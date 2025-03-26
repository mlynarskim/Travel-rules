import Foundation
import Darwin

class CountryInfoService: ObservableObject {
    @Published var countryInfo: CountryInfo?
    
    func fetchCountryInfo(countryCode: String) {
        if let info = getCountryInfo(for: countryCode) {
            DispatchQueue.main.async {
                self.countryInfo = info
            }
        }
    }
    
    func getCountryInfo(for countryCode: String) -> CountryInfo? {
        switch countryCode {
            
                case "AT":
                    return CountryInfo(
                        countryCode: "AT",
                        emergencyNumbers: .init(
                            police: "133",
                            ambulance: "144",
                            fire: "122",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://gesundheit.gv.at"),
                            .init(title: "government_website".appLocalized, url: "http://bmeia.gv.at")
                        ],
                        embassyInfo: "Austria Federal Ministry: +43 1 53115"
                    )
                case "BE":
                    return CountryInfo(
                        countryCode: "BE",
                        emergencyNumbers: .init(
                            police: "101",
                            ambulance: "100",
                            fire: "100",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://health.belgium.be"),
                            .init(title: "government_website".appLocalized, url: "http://diplomatie.belgium.be")
                        ],
                        embassyInfo: "Belgium Ministry of Foreign Affairs: +32 2 501 81 11"
                    )
                case "BG":
                    return CountryInfo(
                        countryCode: "BG",
                        emergencyNumbers: .init(
                            police: "166",
                            ambulance: "150",
                            fire: "160",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://mh.government.bg"),
                            .init(title: "government_website".appLocalized, url: "http://mfa.bg")
                        ],
                        embassyInfo: "Bulgarian Ministry of Foreign Affairs: +359 2 948 25 78"
                    )
                case "HR":
                    return CountryInfo(
                        countryCode: "HR",
                        emergencyNumbers: .init(
                            police: "192",
                            ambulance: "194",
                            fire: "193",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://zdravlje.gov.hr"),
                            .init(title: "government_website".appLocalized, url: "http://mvep.gov.hr")
                        ],
                        embassyInfo: "Croatian Ministry of Foreign Affairs: +385 1 4569 966"
                    )
                case "CY":
                    return CountryInfo(
                        countryCode: "CY",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://moh.gov.cy"),
                            .init(title: "government_website".appLocalized, url: "http://mfa.gov.cy")
                        ],
                        embassyInfo: "Cyprus Ministry of Foreign Affairs: +357 22 805 200"
                    )
                case "CZ":
                    return CountryInfo(
                        countryCode: "CZ",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "155",
                            fire: "150",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://mzcr.cz"),
                            .init(title: "government_website".appLocalized, url: "http://mzv.cz")
                        ],
                        embassyInfo: "Czech Ministry of Foreign Affairs: +420 224 181 111"
                    )
                case "DK":
                    return CountryInfo(
                        countryCode: "DK",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://sst.dk"),
                            .init(title: "government_website".appLocalized, url: "http://um.dk")
                        ],
                        embassyInfo: "Danish Ministry of Foreign Affairs: +45 33 92 00 00"
                    )
                case "EE":
                    return CountryInfo(
                        countryCode: "EE",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://terviseamet.ee"),
                            .init(title: "government_website".appLocalized, url: "http://vm.ee")
                        ],
                        embassyInfo: "Estonian Ministry of Foreign Affairs: +372 637 7600"
                    )
                case "FI":
                    return CountryInfo(
                        countryCode: "FI",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://valvira.fi"),
                            .init(title: "government_website".appLocalized, url: "http://um.fi")
                        ],
                        embassyInfo: "Finnish Ministry of Foreign Affairs: +358 9 160 05"
                    )
                case "FR":
                    return CountryInfo(
                        countryCode: "FR",
                        emergencyNumbers: .init(
                            police: "17",
                            ambulance: "15",
                            fire: "18",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://solidarites-sante.gouv.fr"),
                            .init(title: "government_website".appLocalized, url: "http://diplomatie.gouv.fr")
                        ],
                        embassyInfo: "French Ministry of Foreign Affairs: +33 1 43 17 53 53"
                    )
                case "GR":
                    return CountryInfo(
                        countryCode: "GR",
                        emergencyNumbers: .init(
                            police: "100",
                            ambulance: "166",
                            fire: "199",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://eody.gov.gr"),
                            .init(title: "government_website".appLocalized, url: "http://mfa.gr")
                        ],
                        embassyInfo: "Greek Ministry of Foreign Affairs: +30 210 368 1735"
                    )
                case "ES":
                    return CountryInfo(
                        countryCode: "ES",
                        emergencyNumbers: .init(
                            police: "091",
                            ambulance: "061",
                            fire: "080",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://sanidad.gob.es"),
                            .init(title: "government_website".appLocalized, url: "http://exteriores.gob.es")
                        ],
                        embassyInfo: "Spanish Ministry of Foreign Affairs: +34 91 379 16 50"
                    )
                case "NL":
                    return CountryInfo(
                        countryCode: "NL",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://government.nl"),
                            .init(title: "government_website".appLocalized, url: "http://government.nl")
                        ],
                        embassyInfo: "Dutch Ministry of Foreign Affairs: +31 70 348 47 47"
                    )
                case "IE":
                    return CountryInfo(
                        countryCode: "IE",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://hse.ie"),
                            .init(title: "government_website".appLocalized, url: "http://gov.ie")
                        ],
                        embassyInfo: "Irish Ministry of Foreign Affairs: +353 1 408 2000"
                    )
                case "LV":
                    return CountryInfo(
                        countryCode: "LV",
                        emergencyNumbers: .init(
                            police: "110",
                            ambulance: "113",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://vm.gov.lv"),
                            .init(title: "government_website".appLocalized, url: "http://mfa.gov.lv")
                        ],
                        embassyInfo: "Latvian Ministry of Foreign Affairs: +371 67016 100"
                    )
                case "LT":
                    return CountryInfo(
                        countryCode: "LT",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://sam.lrv.lt"),
                            .init(title: "government_website".appLocalized, url: "http://urm.lt")
                        ],
                        embassyInfo: "Lithuanian Ministry of Foreign Affairs: +370 5 236 25 16"
                    )
                case "LU":
                    return CountryInfo(
                        countryCode: "LU",
                        emergencyNumbers: .init(
                            police: "113",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://sante.public.lu"),
                            .init(title: "government_website".appLocalized, url: "http://mae.lu")
                        ],
                        embassyInfo: "Luxembourg Ministry of Foreign Affairs: +352 247 847 47"
                    )
                case "MT":
                    return CountryInfo(
                        countryCode: "MT",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://health.gov.mt"),
                            .init(title: "government_website".appLocalized, url: "http://gov.mt")
                        ],
                        embassyInfo: "Malta Ministry of Foreign Affairs: +356 2204 2200"
                    )
                case "DE":
                    return CountryInfo(
                        countryCode: "DE",
                        emergencyNumbers: .init(
                            police: "110",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "Federal Foreign Office", url: "https://www.auswaertiges-amt.de"),
                            .init(title: "Emergency Services", url: "https://www.notruf.eu")
                        ],
                        embassyInfo: "German Federal Foreign Office: +49 30 1817 2000"
                    )
                case "PL":
                    return CountryInfo(
                        countryCode: "PL",
                        emergencyNumbers: .init(
                            police: "997",
                            ambulance: "999",
                            fire: "998",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://mz.gov.pl"),
                            .init(title: "government_website".appLocalized, url: "http://gov.pl")
                        ],
                        embassyInfo: "Polish Ministry of Foreign Affairs: +48 22 523 95 00"
                    )
                case "PT":
                    return CountryInfo(
                        countryCode: "PT",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://sns.gov.pt"),
                            .init(title: "government_website".appLocalized, url: "http://mne.gov.pt")
                        ],
                        embassyInfo: "Portuguese Ministry of Foreign Affairs: +351 21 394 44 00"
                    )
                case "RO":
                    return CountryInfo(
                        countryCode: "RO",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://ms.ro"),
                            .init(title: "government_website".appLocalized, url: "http://mfa.gov.ro")
                        ],
                        embassyInfo: "Romanian Ministry of Foreign Affairs: +40 21 319 90 00"
                    )
                case "SK":
                    return CountryInfo(
                        countryCode: "SK",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "155",
                            fire: "150",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://health.gov.sk"),
                            .init(title: "government_website".appLocalized, url: "http://mzv.sk")
                        ],
                        embassyInfo: "Slovak Ministry of Foreign Affairs: +421 2 5978 3011"
                    )
                case "SI":
                    return CountryInfo(
                        countryCode: "SI",
                        emergencyNumbers: .init(
                            police: "113",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://mz.gov.si"),
                            .init(title: "government_website".appLocalized, url: "http://gov.si")
                        ],
                        embassyInfo: "Slovenian Ministry of Foreign Affairs: +386 1 478 2345"
                    )
                case "SE":
                    return CountryInfo(
                        countryCode: "SE",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://socialstyrelsen.se"),
                            .init(title: "government_website".appLocalized, url: "http://gov.se")
                        ],
                        embassyInfo: "Swedish Ministry of Foreign Affairs: +46 8 405 10 00"
                    )
                case "HU":
                    return CountryInfo(
                        countryCode: "HU",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://koronavirus.gov.hu"),
                            .init(title: "government_website".appLocalized, url: "http://kormany.hu")
                        ],
                        embassyInfo: "Hungarian Ministry of Foreign Affairs: +36 1 458 1000"
                    )
                case "AL":
                    return CountryInfo(
                        countryCode: "AL",
                        emergencyNumbers: .init(
                            police: "129",
                            ambulance: "127",
                            fire: "128",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://shendetesia.gov.al"),
                            .init(title: "government_website".appLocalized, url: "http://punetejashtme.gov.al/en/")
                        ],
                        embassyInfo: "Embassy of Albania: +355 4 225 2147"
                    )
                    
                case "AD":
                    return CountryInfo(
                        countryCode: "AD",
                        emergencyNumbers: .init(
                            police: "110",
                            ambulance: "116",
                            fire: "118",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://www.govern.ad/en/"),
                            .init(title: "government_website".appLocalized, url: "http://exteriors.ad/en")
                        ],
                        embassyInfo: "Embassy of Andorra: +376 876 876"
                    )
                    
                case "AM":
                    return CountryInfo(
                        countryCode: "AM",
                        emergencyNumbers: .init(
                            police: "911",
                            ambulance: "911",
                            fire: "911",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://moh.am/#"),
                            .init(title: "government_website".appLocalized, url: "http://www.mfa.am/en/")
                        ],
                        embassyInfo: "Embassy of Armenia: +374 10 25 77 76"
                    )
                    
                case "AZ":
                    return CountryInfo(
                        countryCode: "AZ",
                        emergencyNumbers: .init(
                            police: "102",
                            ambulance: "103",
                            fire: "101",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://its.gov.az/"),
                            .init(title: "government_website".appLocalized, url: "http://mfa.gov.az/en")
                        ],
                        embassyInfo: "Embassy of Azerbaijan: +994 12 493 23 50"
                    )
                    
                case "BY":
                    return CountryInfo(
                        countryCode: "BY",
                        emergencyNumbers: .init(
                            police: "102",
                            ambulance: "103",
                            fire: "101",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://minzdrav.gov.by/"),
                            .init(title: "government_website".appLocalized, url: "http://mfa.gov.by/en/")
                        ],
                        embassyInfo: "Embassy of Belarus: +375 17 226 17 77"
                    )
                    
                case "BA":
                    return CountryInfo(
                        countryCode: "BA",
                        emergencyNumbers: .init(
                            police: "122",
                            ambulance: "124",
                            fire: "123",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://www.mz.gov.ba/"),
                            .init(title: "government_website".appLocalized, url: "https://mfa.gov.ba/")
                        ],
                        embassyInfo: "Embassy of Bosnia and Herzegovina: +387 33 565 925"
                    )
                    
                case "GE":
                    return CountryInfo(
                        countryCode: "GE",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://www.moh.gov.ge/"),
                            .init(title: "government_website".appLocalized, url: "https://www.mfa.gov.ge/")
                        ],
                        embassyInfo: "Embassy of Georgia: +995 32 29 16 96"
                    )
                    
                case "IS":
                    return CountryInfo(
                        countryCode: "IS",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://www.landlaeknir.is/"),
                            .init(title: "government_website".appLocalized, url: "https://www.government.is/ministries/foreign-affairs/")
                        ],
                        embassyInfo: "Embassy of Iceland: +354 552 3000"
                    )
                    
                case "XK":
                    return CountryInfo(
                        countryCode: "XK",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://www.msh-ks.org/"),
                            .init(title: "government_website".appLocalized, url: "https://www.mfa-ks.net/")
                        ],
                        embassyInfo: "Embassy of Kosovo: +383 38 22 13 74"
                    )
                    
                case "LI":
                    return CountryInfo(
                        countryCode: "LI",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "112",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://www.llv.li/"),
                            .init(title: "government_website".appLocalized, url: "https://www.llv.li/")
                        ],
                        embassyInfo: "Embassy of Liechtenstein: +423 232 44 88"
                    )
                    
                case "MC":
                    return CountryInfo(
                        countryCode: "MC",
                        emergencyNumbers: .init(
                            police: "17",
                            ambulance: "18",
                            fire: "112",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://www.chpg.mc/"),
                            .init(title: "government_website".appLocalized, url: "https://www.gouv.mc/")
                        ],
                        embassyInfo: "Embassy of Monaco: +377 93 15 23 60"
                    )
                    
                case "MD":
                    return CountryInfo(
                        countryCode: "MD",
                        emergencyNumbers: .init(
                            police: "902",
                            ambulance: "903",
                            fire: "901",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://msmps.gov.md/"),
                            .init(title: "government_website".appLocalized, url: "https://mfa.gov.md/")
                        ],
                        embassyInfo: "Embassy of Moldova: +373 22 23 35 71"
                    )
                    
                case "NO":
                    return CountryInfo(
                        countryCode: "NO",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "113",
                            fire: "110",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://helsenorge.no/"),
                            .init(title: "government_website".appLocalized, url: "https://www.regjeringen.no/")
                        ],
                        embassyInfo: "Embassy of Norway: +47 23 13 60 00"
                    )
                    
                case "SM":
                    return CountryInfo(
                        countryCode: "SM",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "118",
                            fire: "115",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://www.iss.sm/"),
                            .init(title: "government_website".appLocalized, url: "https://www.esteri.sm/")
                        ],
                        embassyInfo: "Embassy of San Marino: +378 0549 881 400"
                    )
                    
                case "RS":
                    return CountryInfo(
                        countryCode: "RS",
                        emergencyNumbers: .init(
                            police: "192",
                            ambulance: "194",
                            fire: "193",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "http://www.zdravlje.gov.rs/"),
                            .init(title: "government_website".appLocalized, url: "https://www.mfa.gov.rs/")
                        ],
                        embassyInfo: "Embassy of Serbia: +381 11 306 57 88"
                    )
                    
                case "CH":
                    return CountryInfo(
                        countryCode: "CH",
                        emergencyNumbers: .init(
                            police: "117",
                            ambulance: "144",
                            fire: "118",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://www.bag.admin.ch/"),
                            .init(title: "government_website".appLocalized, url: "https://www.eda.admin.ch/")
                        ],
                        embassyInfo: "Embassy of Switzerland: +41 31 325 30 00"
                    )
                    
                case "TR":
                    return CountryInfo(
                        countryCode: "TR",
                        emergencyNumbers: .init(
                            police: "155",
                            ambulance: "112",
                            fire: "110",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://www.saglik.gov.tr/"),
                            .init(title: "government_website".appLocalized, url: "https://www.mfa.gov.tr/")
                        ],
                        embassyInfo: "Embassy of Turkey: +90 312 459 40 00"
                    )
                    
                case "UA":
                    return CountryInfo(
                        countryCode: "UA",
                        emergencyNumbers: .init(
                            police: "102",
                            ambulance: "103",
                            fire: "101",
                            general: "112"
                        ),
                        usefulLinks: [
                            .init(title: "healthcare".appLocalized, url: "https://moz.gov.ua/"),
                            .init(title: "government_website".appLocalized, url: "https://mfa.gov.ua/")
                        ],
                        embassyInfo: "Embassy of Ukraine: +380 44 490 03 02"
                    )
                    
                case "VA":
                    return CountryInfo(
                        countryCode: "VA",
                        emergencyNumbers: .init(
                            police: "112",
                            ambulance: "118",
                            fire: "115",
                            general: "112"
                        ),
                        usefulLinks: [],
                        embassyInfo: "Vatican: Health care handled by Italian institutions, embassy: Vatican City State: +39 06 6982 2955"
                    )
                    
                default:
                    return nil
                }
            }
        }

