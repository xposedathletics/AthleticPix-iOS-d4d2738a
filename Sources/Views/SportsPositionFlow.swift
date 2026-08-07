import SwiftUI
 
struct SportPositionFlow: View {
    @EnvironmentObject var store:   AthleteStore
    @EnvironmentObject var session: TrainingSession
    @EnvironmentObject var tech:    TechManager
    @Environment(\.dismiss) var dismiss
    @State private var selSport:    String = ""
    @State private var selPosition: String = ""
 
    let sportIcons = ["Football":"🏈","Flag Football":"🚩","Track & Field (Running)":"🏃","Track & Field (Field)":"🥇","Basketball":"🏀","Baseball":"⚾","Softball":"🥎","Soccer":"⚽"]
 
    var positions: [String] { SPORT_CONFIG[selSport]?.positions ?? [] }
    var kpiKeys:   [String] { selPosition.isEmpty ? [] : (SPORT_CONFIG[selSport]?.kpis[selPosition] ?? []) }
 
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators:false) {
                VStack(alignment:.leading, spacing:20) {
                    // Sport selection
                    SectionLabel("TRAINING SPORT")
                    ForEach(Array(SPORT_CONFIG.keys.sorted()),id:\.self) { sp in
                        Button {
                            selSport = sp; selPosition = ""
                        } label: {
                            HStack(spacing:12) {
                                Text(sportIcons[sp] ?? "🏋️").font(.title2)
                                Text(sp).font(.system(size:15,weight:.black)).foregroundColor(.white)
                                Spacer()
                                if selSport == sp { Image(systemName:"checkmark").foregroundColor(AP.gold) }
                            }.padding(14)
                            .background(selSport==sp ? Color(hex:"8B1A1A").opacity(0.12) : AP.card)
                            .overlay(RoundedRectangle(cornerRadius:12).stroke(selSport==sp ? Color(hex:"8B1A1A").opacity(0.5) : AP.border,lineWidth:1))
                            .cornerRadius(12)
                        }
                    }
 
                    if !selSport.isEmpty {
                        // Position selection
                        SectionLabel("POSITION")
                        LazyVGrid(columns:[GridItem(.adaptive(minimum:80))],spacing:8) {
                            ForEach(positions,id:\.self) { pos in
                                Button(pos) { selPosition = pos }
                                    .font(.system(size:13,weight:.black))
                                    .padding(.horizontal,14).padding(.vertical,10)
                                    .frame(maxWidth:.infinity)
                                    .background(selPosition==pos ? AP.gold.opacity(0.14) : AP.card)
                                    .foregroundColor(selPosition==pos ? AP.gold : .white)
                                    .overlay(RoundedRectangle(cornerRadius:10).stroke(selPosition==pos ? AP.gold.opacity(0.6) : AP.border,lineWidth:1))
                                    .cornerRadius(10)
                            }
                        }
                    }
 
                    if !selPosition.isEmpty {
                        // KPI preview
                        SectionLabel("KEY PERFORMANCE INDICATORS — \(selPosition)")
                        let athleteKPIs = store.selected?.kpis[selPosition] ?? [:]
                        LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:2),spacing:6) {
                            ForEach(kpiKeys,id:\.self) { k in
                                VStack(alignment:.leading,spacing:2) {
                                    Text(k).font(.system(size:9,weight:.bold)).foregroundColor(AP.muted)
                                    Text(athleteKPIs[k] ?? "—").font(.system(size:14,weight:.black)).foregroundColor(athleteKPIs[k] != nil ? AP.gold : Color.white.opacity(0.2))
                                }.padding(9).frame(maxWidth:.infinity,alignment:.leading)
                                .background(AP.card).overlay(RoundedRectangle(cornerRadius:9).stroke(AP.border,lineWidth:1)).cornerRadius(9)
                            }
                        }
 
                        // Focus areas
                        if let ath = store.selected, !ath.focus_areas.isEmpty {
                            SectionLabel("TOP 3 FOCUS AREAS (TRAINING PRIORITY)")
                            HStack(spacing:8) {
                                let colors = [Color(hex:"ef4444"),Color(hex:"f97316"),AP.gold]
                                ForEach(Array(ath.focus_areas.prefix(3).enumerated()),id:\.offset) { i,f in
                                    VStack(spacing:2) {
                                        Text("#\(i+1) Priority").font(.system(size:8,weight:.black)).foregroundColor(colors[i])
                                        Text(f).font(.system(size:12,weight:.black))
                                    }.frame(maxWidth:.infinity).padding(10)
                                    .background(colors[i].opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius:9).stroke(colors[i].opacity(0.4),lineWidth:1))
                                    .cornerRadius(9)
                                }
                            }
                        }
 
                        GradBtn(title:"⚡ Generate Training Plan →") {
                            if let ath = store.selected {
                                session.start(athlete:ath, sport:selSport, position:selPosition,
                                              pastLogs:store.logs.filter{$0.athlete_id==ath.id&&$0.sport==selSport},
                                              equipment:tech.equipment)
                            }
                            dismiss()
                        }
                    }
                }.padding(20)
            }
            .background(AP.dark.ignoresSafeArea())
            .navigationTitle("")
            .toolbar { ToolbarItem(placement:.cancellationAction) { Button("← Back") { dismiss() }.foregroundColor(AP.muted) } }
        }
        .preferredColorScheme(.dark)
    }
}
