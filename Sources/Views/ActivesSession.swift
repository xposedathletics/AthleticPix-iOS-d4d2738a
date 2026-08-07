import SwiftUI
 
struct ActiveSessionView: View {
    @EnvironmentObject var session: TrainingSession
    @EnvironmentObject var tech:    TechManager
    @EnvironmentObject var store:   AthleteStore
 
    var current: Drill? { session.current }
    var adj: IntensityResult? {
        guard let d = current else { return nil }
        return adjustIntensity(drill:d, hr:tech.hr, hrMax:tech.hrMax, rpe:session.rpe)
    }
 
    var body: some View {
        ZStack(alignment:.top) {
            AP.dark.ignoresSafeArea()
            ScrollView(showsIndicators:false) {
                VStack(spacing:0) {
                    // Header
                    HStack {
                        GradText("⚡ AthletixPro", size:18, weight:.black)
                        Spacer()
                        Text("\(session.sport) · \(session.position)").font(.system(size:11)).foregroundColor(AP.muted)
                    }.padding(.horizontal,16).padding(.vertical,10)
                    .background(Color.black.opacity(0.7)).overlay(Divider().opacity(0.3),alignment:.bottom)
 
                    // Progress bar
                    VStack(spacing:4) {
                        HStack {
                            Text("Drill \(session.logs.count+1) of \(session.plan.count)").font(.system(size:10,weight:.black)).foregroundColor(AP.muted)
                            Spacer()
                            Text("\(Int(session.progress))% complete").font(.system(size:10,weight:.black)).foregroundColor(AP.muted)
                        }
                        APProgressBar(pct:session.progress)
                    }.padding(.horizontal,16).padding(.vertical,8)
 
                    // Wearable strip
                    if tech.wearableConnected {
                        WearableStrip().environmentObject(tech).environmentObject(session)
                    }
 
                    // Drill plan strip
                    DrillPlanStrip().environmentObject(session)
 
                    // Current drill card
                    if let drill = adj?.drill ?? current {
                        DrillCard(drill:drill, adj:adj ?? IntensityResult(drill:drill,adjusted:false,reason:""))
                            .environmentObject(session).environmentObject(tech).environmentObject(store)
                    }
                }
            }
        }
    }
}
 
struct WearableStrip: View {
    @EnvironmentObject var tech: TechManager
    @EnvironmentObject var session: TrainingSession
    var body: some View {
        VStack(alignment:.leading, spacing:4) {
            ScrollView(.horizontal, showsIndicators:false) {
                HStack(spacing:16) {
                    WearStat(label:"HR",     value:"\(tech.hr)",                   unit:"bpm",  color:Color(hex:tech.hrZone.1))
                    WearStat(label:"Zone",   value:tech.hrZone.0,                   unit:"",     color:Color(hex:tech.hrZone.1))
                    WearStat(label:"HRV",    value:"\(tech.hrv)",                  unit:"ms",   color:Color(hex:"60a5fa"))
                    WearStat(label:"SpO₂",   value:"\(tech.spo2)",                 unit:"%",    color:Color(hex:"6ee7a0"))
                    WearStat(label:"Speed",  value:String(format:"%.1f",tech.speed), unit:"mph",  color:AP.gold)
                    WearStat(label:"Dist",   value:String(format:"%.2f",tech.distance),unit:"mi",color:AP.gold)
                    WearStat(label:"Accel",  value:String(format:"%.1f",tech.acceleration),unit:"m/s²",color:Color(hex:"f97316"))
                }.padding(.horizontal,16)
            }
            if let adj = session.plan.indices.contains(session.currentIdx) ? adjustIntensity(drill:session.plan[session.currentIdx],hr:tech.hr,hrMax:tech.hrMax,rpe:session.rpe) : nil, adj.adjusted {
                Text("⚡ Auto-adjusted: \(adj.reason)").font(.system(size:10,weight:.bold)).foregroundColor(Color(hex:"f97316")).padding(.horizontal,16)
            }
        }.padding(.vertical,8)
        .background(Color.white.opacity(0.04)).overlay(Divider().opacity(0.3),alignment:.bottom)
    }
}
 
struct WearStat: View {
    let label,value,unit: String; let color: Color
    var body: some View {
        VStack(spacing:1) {
            HStack(alignment:.lastTextBaseline, spacing:1) {
                Text(value).font(.system(size:15,weight:.black,design:.monospaced)).foregroundColor(color)
                Text(unit).font(.system(size:8)).foregroundColor(color.opacity(0.7))
            }
            Text(label).font(.system(size:8,weight:.bold)).foregroundColor(AP.muted)
        }.frame(minWidth:48)
    }
}
 
struct DrillPlanStrip: View {
    @EnvironmentObject var session: TrainingSession
    var body: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:5) {
                ForEach(Array(session.plan.enumerated()),id:\.element.id) { i,d in
                    VStack(spacing:1) {
                        Text(d.status == .done ? "✓" : "\(i+1)").font(.system(size:9,weight:.black))
                            .foregroundColor(d.status == .done ? Color(hex:"6ee7a0") : i==session.currentIdx ? AP.gold : AP.muted)
                        Text(d.name.split(separator:" ").prefix(2).joined(separator:" ")).font(.system(size:7)).foregroundColor(AP.muted).lineLimit(2).multilineTextAlignment(.center)
                    }.frame(minWidth:60).padding(.horizontal,7).padding(.vertical,6)
                    .background(d.status == .done ? Color(hex:"6ee7a0").opacity(0.08) : i==session.currentIdx ? AP.gold.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius:8).stroke(d.status == .done ? Color(hex:"6ee7a0").opacity(0.4) : i==session.currentIdx ? AP.gold.opacity(0.5) : AP.border,lineWidth:1))
                    .cornerRadius(8)
                }
            }.padding(.horizontal,16).padding(.vertical,8)
        }
    }
}
 
struct DrillCard: View {
    let drill: Drill; let adj: IntensityResult
    @EnvironmentObject var session: TrainingSession
    @EnvironmentObject var tech:    TechManager
    @EnvironmentObject var store:   AthleteStore
 
    var body: some View {
        VStack(spacing:12) {
            // Title row
            HStack(alignment:.top) {
                VStack(alignment:.leading,spacing:3) {
                    Text(drill.name).font(.system(size:18,weight:.black))
                    Text("\(drill.cat) · \(session.sport) · \(session.position)").font(.system(size:11)).foregroundColor(AP.muted)
                }
                Spacer()
                APTag(text:adj.adjusted ? "ADJUSTED" : "PLAN", color:adj.adjusted ? Color(hex:"f97316") : AP.gold)
            }
 
            // Metrics
            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:8) {
                MetricCard(label:"Sets",  value:"\(drill.sets)")
                MetricCard(label:"Reps",  value:"\(drill.reps)")
                MetricCard(label:"Done",  value:"\(session.setsDone)/\(drill.sets)", color:Color(hex:"6ee7a0"))
                MetricCard(label:"Clock", value:fmtSecs(session.drillClock), color:Color(hex:"60a5fa"))
            }
 
            // Timer controls
            HStack(spacing:8) {
                Button {
                    session.toggleClock(); tech.isRunning = session.drillRunning
                } label: {
                    Text(session.drillRunning ? "⏸ Pause" : "▶ Start Drill").font(.system(size:15,weight:.black)).frame(maxWidth:.infinity).padding(12)
                        .background(LinearGradient(colors: session.drillRunning ? [Color(hex:"8B1A1A").opacity(0.5), Color(hex:"8B1A1A").opacity(0.5)] : [AP.gradStart, AP.gradEnd], startPoint:.leading, endPoint:.trailing))
                        .foregroundColor(.white).cornerRadius(10)
                }
                Button {
                    if session.setsDone < drill.sets {
                        session.setsDone += 1
                        tech.recordSplit(setNumber:session.setsDone)
                    }
                } label: {
                    Text("✓ Set \(session.setsDone+1)").font(.system(size:13,weight:.black)).frame(maxWidth:.infinity).padding(12)
                        .background(AP.card).foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius:10).stroke(AP.border,lineWidth:1)).cornerRadius(10)
                }
            }
 
            // RPE
            VStack(spacing:4) {
                HStack {
                    Text("RPE — Rate of Perceived Exertion").font(.system(size:10,weight:.black)).foregroundColor(AP.muted)
                    Spacer()
                    Text("\(session.rpe)/10").font(.system(size:11,weight:.black)).foregroundColor(session.rpe>=8 ? Color(hex:"ef4444") : session.rpe>=5 ? Color(hex:"f97316") : AP.gold)
                }
                Slider(value:.init(get:{Double(session.rpe)},set:{session.rpe=Int($0)}),in:1...10,step:1).accentColor(AP.gold)
            }
 
            // SMARTSPEED splits
            if tech.smartspeedConnected && !tech.splits.isEmpty {
                VStack(alignment:.leading,spacing:6) {
                    Text("⚡ SMARTSPEED SPLITS").font(.system(size:9,weight:.black)).foregroundColor(AP.muted).tracking(1)
                    ScrollView(.horizontal,showsIndicators:false) {
                        HStack(spacing:6) {
                            ForEach(tech.splits) { sp in
                                VStack(spacing:1) {
                                    Text(String(format:"%.2fs",sp.time)).font(.system(size:12,weight:.black,design:.monospaced)).foregroundColor(Color(hex:"a78bfa"))
                                    Text("Set \(sp.setNumber)").font(.system(size:8)).foregroundColor(AP.muted)
                                }.padding(.horizontal,10).padding(.vertical,6)
                                .background(Color(hex:"a78bfa").opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color(hex:"a78bfa").opacity(0.3),lineWidth:1)).cornerRadius(8)
                            }
                        }
                    }
                }
            }
 
            // Complete
            Button {
                if let ath = store.selected { session.completeDrill(tech:tech,athlete:ath) }
            } label: {
                Text("✅ Complete Drill → Next").font(.system(size:14,weight:.black)).frame(maxWidth:.infinity).padding(12)
                    .background(Color(hex:"6ee7a0").opacity(0.14)).foregroundColor(Color(hex:"6ee7a0"))
                    .overlay(RoundedRectangle(cornerRadius:12).stroke(Color(hex:"6ee7a0").opacity(0.35),lineWidth:1)).cornerRadius(12)
            }
        }.padding(14).background(AP.card).overlay(RoundedRectangle(cornerRadius:14).stroke(adj.adjusted ? Color(hex:"f97316").opacity(0.4) : AP.border,lineWidth:1)).cornerRadius(14).padding(.horizontal,16).padding(.bottom,8)
    }
}
