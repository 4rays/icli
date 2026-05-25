import ProjectDescription

public let teamReverseDomain = "net.4rays"
public let teamID = "HCTW65QDC4"
public let appTarget: TargetReference = "iCLI"
public let cliTarget: TargetReference = "icli"

extension ProjectDescription.DeploymentTargets {
  public static var platforms: DeploymentTargets {
    .macOS("15.0")
  }
}

extension ProjectDescription.Destinations {
  public static var destinations: Destinations {
    [.mac]
  }
}
