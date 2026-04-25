import ProjectDescription

public let teamReverseDomain = "net.4rays"
public let appTarget: TargetReference = "iCLI"
public let cliTarget: TargetReference = "icli"

public extension ProjectDescription.DeploymentTargets {
    static var platforms: DeploymentTargets {
        .macOS("15.0")
    }
}

public extension ProjectDescription.Destinations {
    static var destinations: Destinations {
        [.mac]
    }
}
