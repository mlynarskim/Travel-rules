import Foundation
import SwiftUI

struct ListItemView: Identifiable, Hashable {
var id: UUID = UUID()
var type : ListItem
var title: String
var subtitle: String
var isCompleted: Bool = false
}


enum ListItem: String, CaseIterable, Codable, Hashable {
    case BathroomItems
    case KitchenItems
    case ClothesItems
    case UsefulItems
    case ElectronicsItems
    case CampingItems
    case ToolsItems
    case OtherItems
}


var BathroomItems: [String] = [
    "Antibacterial hand gel",
    "Moisturizing wipes",
    "Deodorant, perfume",
    "Disposable rubber gloves",
    "Cream",
    "Mirror",
    "Shaving razor",
    "Soap, shampoo",
    "Toilet paper",
    "Toothpaste",
    "Tweezers",
    "Toilet fluid",
    "Portable shower",
    "Towels",
    "Dry shampoo",
    "Toothbrush",
    "Portable toilet"
]

let KitchenItems: [String] = [
    "Water bottle",
    "Kettle",
    "Cutting board",
    "Pots, pans",
    "Trash can and bags",
    "Thermos",
    "Scissors",
    "Wine and beer opener",
    "Dish soap",
    "Cooking utensils",
    "Dishcloths, sponges",
    "Plates, bowls",
    "Travel mug",
    "Coffee maker",
    "Water containers",
    "Insect repellent",
    "Knives, forks, spoons",
    "Food storage containers"
]

let ClothesItems: [String] = [
    "Sweatshirt",
    "Long-sleeved blouse",
    "Underwear",
    "Trekking shoes",
    "Shower sandals",
    "Shirt",
    "Shorts",
    "Raincoat",
    "Jacket",
    "Sunglasses",
    "Socks",
    "Sweatpants, leggings",
    "Skirt",
    "Dress",
    "T-shirts",
    "Sneakers",
    "Regular pants"
]

let UsefulItems: [String] = [
    "Pen",
    "Board games, playing cards",
    "Blanket",
    "Night lamp",
    "Mosquito net",
    "Bedding",
    "Pillows, duvet",
    "Storage boxes, baskets",
    "Clothespins",
    "Clothesline",
    "Breakfast table",
    "Favorite book",
    "Earplugs",
    "Notebook, journal",
    "Window curtains"
]

let ElectronicsItems: [String] = [
    "Camera",
    "Wireless speaker",
    "GPS",
    "USB cables, chargers",
    "Dashcam",
    "Laptop/tablet",
    "Phone",
    "USB adapters",
    "Spare batteries",
    "Memory cards",
    "Chargers for devices"
]

let CampingItems: [String] = [
    "Hammock with attachments",
    "Beach blanket",
    "Camping chairs",
    "Sunscreen",
    "Flashlight/lamp",
    "Tent and sleeping bag",
    "Pocket knife",
    "Shovel",
    "Axe",
    "Mosquito and tick repellent",
    "Folding table"
]

let ToolsItems: [String] = [
    "Additional water pump",
    "First aid kit",
    "Gas detector",
    "Pepper spray",
    "Reflective vests",
    "Jumper cables",
    "Gas canister",
    "Keys",
    "Padlock",
    "Car jack",
    "Hammer",
    "Current meter",
    "Pliers",
    "Tire compressor",
    "Protective gloves",
    "Silicone",
    "Screwdriver and screws",
    "Triangle warning sign",
    "Zip ties",
    "WD40",
    "Spare oil"
    
]

let OtherItems: [String] = [
    "Phone holder for the car",
    "Laundry basket/bag",
    "Needle, thread, safety pin",
    "Dustpan and brush",
    "Floor cloth",
    "Water hose",
    "Hose connectors and taps",
    "Wheel ramps",
    "Plasters and bandages",
    "Wound disinfectant",
    "Medication: painkillers, antidiarrheals",
    "Personal documents",
    "Insurance, EHIC card",
    "Driver's license"
]
