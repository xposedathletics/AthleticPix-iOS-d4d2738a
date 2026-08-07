import SwiftUI
 
struct CompleteView: View {
    @EnvironmentObject var session: TrainingSession
    @EnvironmentObject var store:   AthleteStore
    @EnvironmentObject var tech:    TechManager
    @State private var sending = false
    @State private var sent    = false
 
    var body: some View {
        ScrollView(showsIndicators:false) {
            VStack(spacing:0) {
                // Header
                VStack(spacing:4) {
                    GradText("🏆 Session Complete!", size:24, weight:.black)
                    if let ath = store.selected { Text("\(ath.full_name) · \(session.sport) · \(session.position)").font(.system(size:12)).foregroundColor(AP.muted) }
                }.frame(maxWidth:.infinity).padding(20)
                .background(Color.black.opacity(0.6)).overlay(Divider().opacity(0.3),alignment:.bottom)
 
                VStack(alignment:.leading, spacing:20) {
                    if let s = session.summary {
                        // Summary grid
                        SectionLabel("SESSION SUMMARY")
                        LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:2),spacing:8) {
                            MetricCard(label:"Duration",    value:"\(s.duration_min) min", color:AP.gold)
                            MetricCard(label:"Drills Done", value:"\(s.completed)/\(s.total_drills)", color:Color(hex:"6ee7a0"))
                            MetricCard(label:"Avg HR",      value:"\(s.avg_hr) bpm", color:Color(hex:"ef4444"))
                            MetricCard(label:"Max HR",      value:"\(s.max_hr) bpm", color:Color(hex:"f97316"))
                            MetricCard(label:"Distance",    value:String(format:"%.2f mi",s.total_distance), color:Color(hex:"60a5fa"))
                            MetricCard(label:"Avg RPE",     value:String(format:"%.1f",s.avg_rpe), color:AP.gold)
                            MetricCard(label:"Total Sets",  value:"\(s.total_sets)", color:Color(hex:"a78bfa"))
                            MetricCard(label:"Auto-Adjust", value:"\(s.intensity_adjustments)×", color:Color(hex:"f97316"))
                        }
                    }
 
                    // Drill breakdown
                    SectionLabel("DRILL BREAKDOWN")
                    ForEach(session.logs) { log in DrillLogRow(log:log) }
 
                    // Notifications
                    SectionLabel("COMPLETION NOTIFICATIONS")
                    NotifPanel().environmentObject(store).environmentObject(session)
 
                    // Email button
                    Button {
                        sendEmails()
                    } label: {
                        Text(sending ? "Sending…" : sent ? "✅ Emails Sent!" : "📧 Send Completion Emails").font(.system(size:14,weight:.black)).frame(maxWidth:.infinity).padding(14)
                            .background(LinearGradient(colors: sent ? [Color(hex:"146428"), Color(hex:"146428")] : [AP.gradStart, AP.gradEnd], startPoint:.leading, endPoint:.trailing))
                            .foregroundColor(.white).cornerRadius(12)
                    }.disabled(sending)
 
                    Button {
                        session.phase = .idle
                        tech.isRunning = false
                    } label: {
                        Text("← Back to Home").font(.system(size:13,weight:.bold)).frame(maxWidth:.infinity).padding(12)
                            .background(AP.card).foregroundColor(AP.muted)
                            .overlay(RoundedRectangle(cornerRadius:12).stroke(AP.border,lineWidth:1)).cornerRadius(12)
                    }
                }.padding(.horizontal,20).padding(.top,20).padding(.bottom,40)
            }
        }.background(AP.dark.ignoresSafeArea())
    }
 
    func sendEmails() {
        sending = true
        // POST to Base44 backend function: sendWorkoutSummary
        guard let url = URL(string:"https://app.base44.com/api/apps/69ded3c1e03c8b3a272c497a/functions/sendWorkoutSummary") else { return }
        var req = URLRequest(url:url); req.httpMethod = "POST"
        req.setValue("application/json",forHTTPHeaderField:"Content-Type")
        if let data = try? JSONEncoder().encode(session.summary) { req.httpBody = data }
        URLSession.shared.dataTask(with:req) { _,_,_ in
            DispatchQueue.main.async { sending = false; sent = true }
        }.resume()
    }
}
 
struct DrillLogRow: View {
    let log: TrainingLog
    var body: some View {
        VStack(alignment:.leading,spacing:6) {
            HStack {
                Text(log.drill_name).font(.system(size:14,weight:.black))
                Spacer()
                let c: Color = log.completion_pct >= 90 ? Color(hex:"6ee7a0") : log.completion_pct >= 70 ? AP.gold : Color(hex:"ef4444")
                APTag(text:"\(Int(log.completion_pct))%",color:c)
            }
            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:6) {
                MetricCard(label:"Sets",  value:"\(log.sets_completed)/\(log.sets)")
                MetricCard(label:"Time",  value:fmtSecs(Int(log.actual_time_sec)), color:Color(hex:"60a5fa"))
                MetricCard(label:"Avg HR",value:"\(log.heart_rate_avg)", color:Color(hex:"ef4444"))
                MetricCard(label:"RPE",   value:"\(log.rpe)", color:Color(hex:"a78bfa"))
            }
            if log.intensity_adjusted { Text("⚡ \(log.intensity_reason)").font(.system(size:10,weight:.bold)).foregroundColor(Color(hex:"f97316")) }
            if !log.ai_feedback.isEmpty { Text("🤖 \(log.ai_feedback)").font(.system(size:11)).foregroundColor(AP.muted) }
        }.padding(12).background(AP.card).overlay(RoundedRectangle(cornerRadius:12).stroke(AP.border,lineWidth:1)).cornerRadius(12)
    }
}
 
struct NotifPanel: View {
    @EnvironmentObject var store:   AthleteStore
    @EnvironmentObject var session: TrainingSession
    var body: some View {
        VStack(alignment:.leading,spacing:0) {
            let parents  = store.parents.filter { $0.athlete_ids.contains(store.selected?.id ?? "") }
            let coaches  = store.selected?.coach_emails ?? [:]
            let admins   = store.selected?.admin_emails ?? []
            ForEach(parents) { p in
                NotifRow(icon:"👨‍👩‍👦", name:p.full_name, email:p.email, last:false)
            }
            ForEach(Array(coaches.keys.sorted()),id:\.self) { sp in
                NotifRow(icon:"🏟", name:"Coach (\(sp))", email:coaches[sp] ?? "", last:false)
            }
            ForEach(admins,id:\.self) { em in
                NotifRow(icon:"🏫", name:"School Admin", email:em, last:true)
            }
            if parents.isEmpty && coaches.isEmpty && admins.isEmpty {
                Text("No notification recipients — add contacts in Comeback Season").font(.system(size:12)).foregroundColor(AP.muted).padding(10)
            }
        }.background(AP.card).overlay(RoundedRectangle(cornerRadius:12).stroke(AP.border,lineWidth:1)).cornerRadius(12)
    }
}
 
struct NotifRow: View {
    let icon,name,email: String; let last: Bool
    var body: some View {
        HStack {
            Text("\(icon) \(name)").font(.system(size:12,weight:.bold))
            Spacer()
            Text(email).font(.system(size:11)).foregroundColor(AP.muted)
        }.padding(.horizontal,12).padding(.vertical,8)
        if !last { Divider().opacity(0.3).padding(.horizontal,12) }
    }
}
