import Foundation

@main
struct ICli {
    static func main() {
        Task {
            await CommandRouter.run()
        }
        RunLoop.main.run()
    }
}
