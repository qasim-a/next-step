import WidgetKit
import SwiftData
import Foundation

struct FollowUpWidgetEntry: TimelineEntry {
    let date: Date
    let followUps: [FollowUp]
}

struct FollowUpWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FollowUpWidgetEntry {
        FollowUpWidgetEntry(date: .now, followUps: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (FollowUpWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FollowUpWidgetEntry>) -> Void) {
        let entry = currentEntry()
        // System-scheduled refresh budget, not a tight custom interval — see
        // specs/005-polish/research.md. In-app changes get a prompter refresh via
        // SwiftDataContactRepository's explicit WidgetCenter.reloadAllTimelines() calls.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> FollowUpWidgetEntry {
        let container = SharedModelContainer.make(inMemory: false)
        let context = ModelContext(container)
        let followUps = (try? context.fetch(FetchDescriptor<FollowUp>())) ?? []
        return FollowUpWidgetEntry(date: .now, followUps: FollowUpWidgetContent.select(followUps))
    }
}
