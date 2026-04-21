import Foundation

@main
struct ICli {
    static func main() async {
        await CommandRouter.run()
    }
}
