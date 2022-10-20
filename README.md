# BoteCore



## Usage

This library has two main components, which should be used by any application using `BoteCore`. These are `ConfigurationManager` and `SyncOrchestrator`. Both components work independet from each other, but can be used together and are also designed to be used together.

The `ConfigurationManager` handles saving and loading synchronization configurations to/from the UserDefaults, thus persisting them when the program is closed. A configuration is saved in a `Configuration` object.

The `SyncOrchestrator` handles managing active synchronizations, starting and stopping them. A synchronization in the `SyncOrchestrator` is presented by a `SyncItem`, therefore the `SyncOrchestrator` holds a property `syncItems`, which store all registered synchronization configurations. `Configurations` can be registered in the `SyncOrchestrator` with `register(configuration:)`, this will create a `SyncItem` for this configuration. A registered configuration can be started and stopped using `startSynchronizing` and `stopSynchronizing`.  It can also be unregistered using `unregister(configuration:)`, which will also remove it from `syncItems`.

You can use both components together, by loading configurations from the `ConfigurationManager`, then registering them in the `SyncOrchestrator` and start them if needed. New configurations can be first stored using `ConfigurationManager` and then used with `SyncOrchestrator`.



## Example usage
```swift
guard let configManager = ConfigurationManager.init(()) else { return }
syncOrchestrator = SyncOrchestrator()
for configuration in configManager.configurations {
    do {
        let item = try syncOrchestrator.register(configuration: configuration)
        try syncOrchestrator.startSynchronizing(for: item, errorHandler: { (item, error) in
            // handle errors which occure while synchronization is running
        })
    } catch let error {
        // handle errors which occure when trying to start the sync
    }
}
```

Alternatively you can let `SyncOrchestrator` do the work of registering and starting an array of configurations for you. The downside using this method is, that when an error occurs with one configuration, the remaining configurations are skipped because the function will throw an error and return.
```swift
guard let configManager = ConfigurationManager.init(()) else { return }
syncOrchestrator = SyncOrchestrator()
do {
    try syncOrchestrator = SyncOrchestrator(configurations: configManager.configurations, errorHandler: { (item, error) in
        // handle errors which occure while synchronization is running
    })
} catch let error {
    // handle errors which occure when trying to start the sync
}
```
