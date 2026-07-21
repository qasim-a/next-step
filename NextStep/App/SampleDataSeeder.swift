import Foundation

/// Populates the store with realistic demo data on first launch when the `-SeedSampleData`
/// launch argument is present. Not wired into any spec — a standalone demo aid, gated so it
/// never runs during normal use, tests, or App Store builds.
@MainActor
enum SampleDataSeeder {
    static func seedIfNeeded(repository: ContactRepository?) async {
        guard ProcessInfo.processInfo.arguments.contains("-SeedSampleData") else { return }
        guard let repository else { return }
        guard let existing = try? repository.fetchAll(), existing.isEmpty else { return }

        let calendar = Calendar.current
        func daysAgo(_ n: Int) -> Date { calendar.date(byAdding: .day, value: -n, to: .now)! }
        func daysFromNow(_ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: .now)! }

        do {
            let sarah = NetworkingContact(
                name: "Sarah Chen",
                company: try repository.findOrCreateCompany(named: "Google"),
                jobTitle: "Technical Recruiter",
                contactHandle: "sarah.chen@google.com",
                howWeMet: "Reached out on LinkedIn about a Platform Engineer role",
                relationshipCategory: .recruiter,
                relationshipStrength: 4,
                notes: "Very responsive. Mentioned a referral bonus if I know other candidates."
            )
            try repository.save(sarah)
            try repository.saveInteraction(
                Interaction(
                    type: .linkedInMessage, date: daysAgo(14),
                    notes: "She reached out about a Platform Engineering opening.",
                    outcome: "Agreed to a call next week", nextAction: "Send updated resume"
                ), for: sarah
            )
            try repository.saveInteraction(
                Interaction(
                    type: .phoneOrVideoCall, date: daysAgo(9),
                    notes: "30-minute intro call, discussed team and leveling.",
                    outcome: "Moving to phone screen with hiring manager",
                    nextAction: "Prep for phone screen — review distributed systems basics"
                ), for: sarah
            )

            let michael = NetworkingContact(
                name: "Michael Osei",
                company: try repository.findOrCreateCompany(named: "Stripe"),
                jobTitle: "Engineering Manager",
                contactHandle: "@michael_osei",
                howWeMet: "Introduced by a mutual connection, Diego Ramirez",
                relationshipCategory: .hiringManager,
                relationshipStrength: 5,
                notes: "Leads the Payments Infra team. Very technical, appreciates directness."
            )
            try repository.save(michael)
            try repository.saveInteraction(
                Interaction(
                    type: .inPersonMeeting, date: daysAgo(20),
                    notes: "Coffee chat at a meetup, talked about his team's roadmap.",
                    outcome: "Said to apply directly and he'd flag my application",
                    nextAction: "Apply and follow up once submitted"
                ), for: michael
            )
            try repository.saveInteraction(
                Interaction(
                    type: .interview, date: daysAgo(3),
                    notes: "Onsite loop, four rounds including a system design with his team.",
                    outcome: "Said feedback would come within a week",
                    nextAction: "Send a thank-you note and check in if no word by end of week"
                ), for: michael
            )

            let priya = NetworkingContact(
                name: "Priya Patel",
                company: try repository.findOrCreateCompany(named: "Meta"),
                jobTitle: "Senior Software Engineer",
                contactHandle: "priya.patel@meta.com",
                howWeMet: "Former teammate at a previous job, stayed in touch",
                relationshipCategory: .referral,
                relationshipStrength: 5,
                notes: "Offered to refer me for anything on her org. Prefers email."
            )
            try repository.save(priya)
            try repository.saveInteraction(
                Interaction(
                    type: .email, date: daysAgo(6),
                    notes: "Asked if she'd be open to referring me for an open Staff role.",
                    outcome: "She said yes and asked for my latest resume",
                    nextAction: "Send resume and a short blurb for the referral form"
                ), for: priya
            )

            let diego = NetworkingContact(
                name: "Diego Ramirez",
                company: try repository.findOrCreateCompany(named: "Airbnb"),
                jobTitle: "Product Manager",
                contactHandle: "@diego.builds",
                howWeMet: "Same university, met through the alumni Slack",
                relationshipCategory: .alumnus,
                relationshipStrength: 3,
                notes: "Doesn't work in engineering but knows a lot of the hiring managers."
            )
            try repository.save(diego)
            try repository.saveInteraction(
                Interaction(
                    type: .linkedInConnectionRequest, date: daysAgo(30),
                    notes: "Connected after seeing his post in the alumni group.",
                    outcome: nil, nextAction: nil
                ), for: diego
            )

            let amara = NetworkingContact(
                name: "Amara Okafor",
                company: try repository.findOrCreateCompany(named: "Netflix"),
                jobTitle: "Staff Engineer",
                contactHandle: "amara.okafor@netflix.com",
                howWeMet: "Met at a conference, exchanged cards after her talk",
                relationshipCategory: .peer,
                relationshipStrength: 3,
                notes: "Gave a great talk on caching strategies. Open to grabbing coffee sometime."
            )
            try repository.save(amara)
            try repository.saveInteraction(
                Interaction(
                    type: .email, date: daysAgo(45),
                    notes: "Follow-up email after the conference thanking her for the talk.",
                    outcome: "She replied and suggested coffee next time I'm in the area",
                    nextAction: nil
                ), for: amara
            )

            let james = NetworkingContact(
                name: "James Whitfield",
                company: try repository.findOrCreateCompany(named: "Amazon"),
                jobTitle: "Technical Recruiter",
                contactHandle: "j.whitfield@amazon.com",
                howWeMet: "Cold outreach via LinkedIn about an SDE II role",
                relationshipCategory: .recruiter,
                relationshipStrength: 2,
                notes: "Hasn't responded in a while — may be worth one more nudge."
            )
            try repository.save(james)
            try repository.saveInteraction(
                Interaction(
                    type: .linkedInMessage, date: daysAgo(18),
                    notes: "He messaged about an SDE II opening on AWS.",
                    outcome: "Sent my resume, no response yet", nextAction: "Follow up in a week"
                ), for: james
            )

            // Follow-ups spanning every Today-screen bucket, with varied priority.
            try await repository.saveFollowUp(
                FollowUp(
                    dueDate: daysAgo(2), priority: .high,
                    suggestedAction: "Check in on phone screen scheduling — it's been over a week"
                ), for: sarah
            )
            try await repository.saveFollowUp(
                FollowUp(
                    dueDate: daysAgo(5), priority: .medium,
                    suggestedAction: "Nudge about the SDE II application status"
                ), for: james
            )
            try await repository.saveFollowUp(
                FollowUp(
                    dueDate: .now, priority: .high,
                    suggestedAction: "Send thank-you note for the onsite loop"
                ), for: michael
            )
            try await repository.saveFollowUp(
                FollowUp(
                    dueDate: .now, priority: .medium,
                    suggestedAction: "Send resume and referral blurb"
                ), for: priya
            )
            try await repository.saveFollowUp(
                FollowUp(
                    dueDate: daysFromNow(3), priority: .low,
                    suggestedAction: "Propose a coffee date next time in her city"
                ), for: amara
            )
            try await repository.saveFollowUp(
                FollowUp(
                    dueDate: daysFromNow(7), priority: .medium,
                    suggestedAction: "Ask if he's heard anything about hiring manager introductions"
                ), for: diego
            )

            let completedOne = FollowUp(
                dueDate: daysAgo(10), priority: .medium,
                suggestedAction: "Send initial resume after the LinkedIn intro"
            )
            try await repository.saveFollowUp(completedOne, for: sarah)
            try await repository.completeFollowUp(completedOne)

            let completedTwo = FollowUp(
                dueDate: daysAgo(4), priority: .high,
                suggestedAction: "Confirm onsite interview logistics"
            )
            try await repository.saveFollowUp(completedTwo, for: michael)
            try await repository.completeFollowUp(completedTwo)
        } catch {
            assertionFailure("Sample data seeding failed: \(error)")
        }
    }
}
