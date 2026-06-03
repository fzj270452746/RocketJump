
import UIKit

final class LaunchConductor {

    let holdings = Holdings()
    let nav: UINavigationController
    private let glide = Glide(popping: false)

    init() {
        let deck = OrbitDeck()
        nav = UINavigationController(rootViewController: deck)
        nav.isNavigationBarHidden = true
        nav.delegate = glide
        deck.conductor = self
    }

    func toAtlas() { push(WorldAtlas(conductor: self)) }
    func toRanks() { push(RankWall(holdings: holdings)) }
    func toQuests() { push(QuestScroll(holdings: holdings)) }
    func toAccolades() { push(AccoladeGallery(holdings: holdings)) }

    /// Begin a flight on a chosen world, full-screen modal so the HUD owns it.
    func launchFlight(on world: World) {
        let host = FlightHost(world: world, conductor: self)
        host.modalPresentationStyle = .fullScreen
        nav.topViewController?.present(host, animated: true)
    }

    private func push(_ vc: UIViewController) { nav.pushViewController(vc, animated: true) }
}
