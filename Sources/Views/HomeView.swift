import SwiftUI
 
struct HomeView: View {
    @EnvironmentObject var store:   AthleteStore
    @EnvironmentObject var session: TrainingSession
    @EnvironmentObject var tech:    TechManager
    @State private var showTech   = false
    @State private var showEquip  = false
    @State private var showForm   = false
    @State private var formAthlete = Athlete()
    @State private var sportStep  = false  // false=home, true=sport→position
 
    var body: some View {
        ScrollView(showsIndicators:false) {
            VStack(spacing:0) {
                // ── Header ──────────────────────────────────────────────────
                HStack {
                    VStack(alignment:.leading, spacing:2) {
                        GradText("⚡ AthletixPro", size:26, weight:.black)
                        Text("World-class AI training · Wearable · SMARTSPEED · Camera")
                            .font(.system(size:11)).foregroundColor(AP.muted)
                    }
                    Spacer()
                    Button("+ Athlete") { showForm = true }
                        .font(.system(size:12,weight:.black)).padding(.horizontal,14).padding(.vertical,8)
                        .background(LinearGradient(colors:[AP.gradStart,AP.gradEnd],startPoint:.leading,endPoint:.trailing))
                        .foregroundColor(.white).cornerRadius(10)
                }.padding(.horizontal,20).padding(.top,16).padding(.bottom,10)
                .background(Color.black.opacity(0.55))
                .overlay(Divider().opacity(0.3),alignment:.bottom)
 
                VStack(alignment:.leading, spacing:20) {
                    // ── Tech status ─────────────────────────────────────────
                    HStack(spacing:6) {
                        TechPill(label:"⌚ Wearable",   connected:tech.wearableConnected,   action:{showTech=true})
                        TechPill(label:"📷 Camera",     connected:tech.cameraConnected,      action:{showTech=true})
                        TechPill(label:"⚡ SMARTSPEED", connected:tech.smartspeedConnected,  action:{showTech=true})
                        TechPill(label:"🏋️ Equip (\(tech.equipment.count))", connected:tech.equipment.count>0, action:{showEquip=true})
                    }
 
                    // ── Athlete list ─────────────────────────────────────────
                    SectionLabel("SELECT ATHLETE (FROM COMEBACK SEASON)")
                    if store.loading {
                        ProgressView().frame(maxWidth:.infinity).padding()
                    } else if store.athletes.isEmpty {
                        EmptyAthleteCard { showForm=true }
                    } else {
                        ForEach(store.athletes) { ath in AthleteRow(ath:ath).environmentObject(store) }
                    }
 
                    // ── Selected athlete profile ─────────────────────────────
                    if let ath = store.selected {
                        AthleteProfileCard(ath:ath)
                        GradBtn(title:"Start Training Session →", icon:"🏋️") {
                            sportStep = true
                        }
                    }
                }
                .padding(.horizontal,20).padding(.top,16)
            }
        }
        .background(AP.dark.ignoresSafeArea())
        .onAppear { store.loadAll() }
        .sheet(isPresented:$showTech)  { TechModal().environmentObject(tech) }
        .sheet(isPresented:$showEquip) { EquipModal().environmentObject(tech) }
        .sheet(isPresented:$showForm)  { AthleteFormView(athlete:$formAthlete).environmentObject(store) }
        .sheet(isPresented:$sportStep) { SportPositionFlow().environmentObject(store).environmentObject(session).environmentObject(tech) }
    }
}
 
struct TechPill: View {
    let label:String; let connected:Bool; let action:()->Void
    var body: some View {
        Button(action:action) {
            HStack(spacing:4) {
                Text(label).font(.system(size:9,weight:.bold)).foregroundColor(connected ? Color(hex:"6ee7a0") : AP.muted)
                Circle().fill(connected ? Color(hex:"6ee7a0") : Color(hex:"333333")).frame(width:6,height:6)
            }.padding(.horizontal,9).padding(.vertical,5)
            .background(connected ? Color(hex:"6ee7a0").opacity(0.07) : Color.white.opacity(0.03))
            .overlay(RoundedRectangle(cornerRadius:8).stroke(connected ? Color(hex:"6ee7a0").opacity(0.4) : AP.border,lineWidth:1))
            .cornerRadius(8)
        }
    }
}
 
struct AthleteRow: View {
    let ath: Athlete
    @EnvironmentObject var store: AthleteStore
    var body: some View {
        HStack(spacing:12) {
            Circle().fill(LinearGradient(colors:[AP.gradStart,AP.gradEnd],startPoint:.top,endPoint:.bottom))
                .frame(width:44,height:44)
                .overlay(Text("👤").font(.title3))
            VStack(alignment:.leading,spacing:2) {
                Text(ath.full_name).font(.system(size:15,weight:.black))
                let meta = [ath.age.map{"Age \($0)"}, ath.gender, ath.school, ath.grad_year.isEmpty ? nil : "Class of \(ath.grad_year)"].compactMap{$0}.joined(separator:" · ")
                Text(meta).font(.system(size:11)).foregroundColor(AP.muted)
                HStack(spacing:3) {
                    ForEach(ath.sports.prefix(2),id:\.self) { APTag(text:$0, color:Color(hex:"1A56A0")) }
                    ForEach(ath.focus_areas.prefix(2),id:\.self) { APTag(text:$0) }
                }
            }
            Spacer()
            if ath.height_in > 0 {
                VStack(alignment:.trailing,spacing:1) {
                    Text(htFt(ath.height_in)).font(.system(size:12,weight:.bold))
                    Text("\(Int(ath.weight_lbs)) lbs").font(.system(size:10)).foregroundColor(AP.muted)
                }
            }
        }
        .padding(12)
        .background(store.selected?.id==ath.id ? Color(hex:"8B1A1A").opacity(0.12) : AP.card)
        .overlay(RoundedRectangle(cornerRadius:12).stroke(store.selected?.id==ath.id ? Color(hex:"8B1A1A").opacity(0.5) : AP.border,lineWidth:1))
        .cornerRadius(12)
        .onTapGesture { store.selected = ath }
    }
}
 
struct AthleteProfileCard: View {
    let ath: Athlete
    var body: some View {
        VStack(alignment:.leading,spacing:10) {
            SectionLabel("ATHLETE PROFILE — \(ath.full_name.uppercased())")
            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:8) {
                MetricCard(label:"Height",  value:ath.height_in>0  ? htFt(ath.height_in) : "—")
                MetricCard(label:"Weight",  value:ath.weight_lbs>0 ? "\(Int(ath.weight_lbs))" : "—", color:AP.gold)
                MetricCard(label:"Age",     value:ath.age != nil ? "\(ath.age!)" : "—")
                MetricCard(label:"GPA",     value:ath.gpa>0 ? String(format:"%.1f",ath.gpa) : "—", color:Color(hex:"6ee7a0"))
            }
            if !ath.focus_areas.isEmpty {
                SectionLabel("TOP FOCUS AREAS")
                HStack(spacing:6) {
                    let colors = [Color(hex:"ef4444"),Color(hex:"f97316"),AP.gold]
                    ForEach(Array(ath.focus_areas.prefix(3).enumerated()),id:\.offset) { i,f in
                        VStack(spacing:1) {
                            Text("#\(i+1) Priority").font(.system(size:8,weight:.black)).foregroundColor(colors[i])
                            Text(f).font(.system(size:12,weight:.black))
                        }.padding(.horizontal,12).padding(.vertical,7)
                        .background(colors[i].opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius:9).stroke(colors[i].opacity(0.4),lineWidth:1))
                        .cornerRadius(9)
                    }
                }
            }
        }.padding(14).background(AP.card).overlay(RoundedRectangle(cornerRadius:14).stroke(AP.border,lineWidth:1)).cornerRadius(14)
    }
}
 
struct EmptyAthleteCard: View {
    let action:()->Void
    var body: some View {
        VStack(spacing:12) {
            Text("👤").font(.system(size:32))
            Text("No athletes — add one to get started").font(.system(size:13)).foregroundColor(AP.muted).multilineTextAlignment(.center)
            GradBtn(title:"+ Add Athlete", action:action)
        }.padding(24).frame(maxWidth:.infinity).background(AP.card).overlay(RoundedRectangle(cornerRadius:14).stroke(AP.border,lineWidth:1)).cornerRadius(14)
    }
}

struct TechModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tech: TechManager

    var body: some View {
        NavigationView {
            List {
                Section("Wearable") {
                    ForEach(WEARABLE_DEVICES, id:\.self) { device in
                        Button(device) { tech.connectWearable(device:device) }
                    }
                    if tech.wearableConnected { Button("Disconnect Wearable") { tech.disconnectWearable() } }
                }
                Section("Camera") {
                    ForEach(CAMERA_SYSTEMS, id:\.self) { system in
                        Button(system) { tech.connectCamera(system:system) }
                    }
                    if tech.cameraConnected { Button("Disconnect Camera") { tech.disconnectCamera() } }
                }
                Section("SMARTSPEED") {
                    ForEach(SMARTSPEED_SYSTEMS, id:\.self) { system in
                        Button(system) { tech.connectSMARTSPEED(system:system) }
                    }
                    if tech.smartspeedConnected { Button("Disconnect SMARTSPEED") { tech.disconnectSMARTSPEED() } }
                }
            }
            .navigationTitle("Training Tech")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

struct EquipModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tech: TechManager

    var body: some View {
        NavigationView {
            List(EQUIPMENT_OPTIONS, id:\.self) { item in
                Button {
                    if tech.equipment.contains(item) {
                        tech.equipment.removeAll { $0 == item }
                    } else {
                        tech.equipment.append(item)
                    }
                } label: {
                    HStack {
                        Text(item)
                        Spacer()
                        if tech.equipment.contains(item) { Image(systemName:"checkmark") }
                    }
                }
            }
            .navigationTitle("Equipment")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

struct AthleteFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AthleteStore
    @Binding var athlete: Athlete

    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    TextField("Full name", text:$athlete.full_name)
                    TextField("Date of birth", text:$athlete.dob)
                    Picker("Gender", selection:$athlete.gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    TextField("School", text:$athlete.school)
                    TextField("Graduation year", text:$athlete.grad_year)
                }

                Section("Metrics") {
                    TextField("GPA", value:$athlete.gpa, format:.number)
                    TextField("Height inches", value:$athlete.height_in, format:.number)
                    TextField("Weight lbs", value:$athlete.weight_lbs, format:.number)
                    TextField("Body fat %", value:$athlete.body_fat_pct, format:.number)
                    TextField("Wingspan inches", value:$athlete.wingspan_in, format:.number)
                    TextField("Hand size inches", value:$athlete.hand_size_in, format:.number)
                }

                Section("Sports") {
                    ForEach(SPORT_CONFIG.keys.sorted(), id:\.self) { sport in
                        Button {
                            if athlete.sports.contains(sport) {
                                athlete.sports.removeAll { $0 == sport }
                            } else {
                                athlete.sports.append(sport)
                            }
                        } label: {
                            HStack {
                                Text(sport)
                                Spacer()
                                if athlete.sports.contains(sport) { Image(systemName:"checkmark") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Athlete")
            .toolbar {
                ToolbarItem(placement:.cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement:.confirmationAction) {
                    Button("Save") {
                        athlete.age = ageFrom(dob:athlete.dob)
                        store.saveAthlete(athlete)
                        store.selected = athlete
                        athlete = Athlete()
                        dismiss()
                    }
                    .disabled(athlete.full_name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
