import UIKit
//import CoreMotion
import HealthKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    let healthStore = HKHealthStore()
    let stepType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
    var temStepCount = 0
    var samples : Any?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        let stepsChannel = FlutterMethodChannel(name: "samples.flutter/steps",binaryMessenger: controller.binaryMessenger)
        
        stepsChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            // Note: this method is invoked on the UI thread.
            guard call.method == "getPedometerSteps" else {
                result(FlutterMethodNotImplemented)
                return
            }
            self?.receivePedometerStatus(res: result)
            self?.startObserving(res: result)
    })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    
    func getSteps(completion: @escaping (Double) -> Void){
        let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(quantityType: type,
                                               quantitySamplePredicate: nil,
                                               options: [.cumulativeSum],
                                               anchorDate: startOfDay,
                                               intervalComponents: interval)
        query.initialResultsHandler = { _, result, error in
                var resultCount = 0.0
                result!.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in

                if let sum = statistics.sumQuantity() {
                    // Get steps (they are of double type)
                    resultCount = sum.doubleValue(for: HKUnit.count())
                } // end if

                // Return
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
        }
        
        query.statisticsUpdateHandler = {
            query, statistics, statisticsCollection, error in

            // If new statistics are available
            if let sum = statistics?.sumQuantity() {
                let resultCount = sum.doubleValue(for: HKUnit.count())
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
        }
        
        healthStore.execute(query)
    }

  private func receivePedometerStatus(res: FlutterResult) {
    
    let healthKitTypes: Set = [ stepType! ]
    
    healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { (bool, error) in
        if (bool) {
            // Authorization Successful
            self.getSteps { (result) in
                DispatchQueue.main.async {
                    print(result)
                    self.temStepCount = Int(result)
                }
            }
        }
    }
    res(temStepCount)
    
    healthStore.enableBackgroundDelivery(
                for: stepType!,
                frequency: .immediate,
                withCompletion: { (succeeded: Bool, error: Error?) in
                    if succeeded {
                        print("Enabled background delivery of steps")
                    } else {
                        if let theError = error {
                            print("Failed to enable background delivery of step changes. ")
                            print("Error = \(theError)")
                        }
                    }
                }
            )                
  }
    
    func startObserving(res: FlutterResult) {
        let stepCountObserverQuery = HKObserverQuery(
            sampleType: stepType!,
            predicate: nil){
            (query, completion, error) in
            let stepCountSampleQuery = HKSampleQuery(
                sampleType: self.stepType!,
                    predicate: nil,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil,
                    resultsHandler: {(query, samples, error) in
                        self.samples = samples as Any
                    })
            self.healthStore.execute(stepCountSampleQuery)
        }
        self.receivePedometerStatus(res: res)
//        res(self.samples)

        healthStore.execute(stepCountObserverQuery)
    }
}


//  HKQuery.predicateForQuantitySamples(with: NSComparisonPredicate.Operator.greaterThan, quantity: HKQuantity(unit: HKUnit.count(), doubleValue: 5000.0))
