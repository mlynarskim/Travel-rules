import Foundation
import SwiftUI

struct ListItemView: Identifiable, Hashable {
    var id: UUID = UUID()
    var type: ListItem
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

func getListData() -> [ListItemView] {
    return [
        ListItemView(type: .BathroomItems, title: "bathroom".appLocalized, subtitle: "bathroom_essentials".appLocalized),
        ListItemView(type: .KitchenItems, title: "kitchen".appLocalized, subtitle: "kitchen_essentials".appLocalized),
        ListItemView(type: .ClothesItems, title: "clothes".appLocalized, subtitle: "clothing_essentials".appLocalized),
        ListItemView(type: .UsefulItems, title: "useful".appLocalized, subtitle: "useful_items".appLocalized),
        ListItemView(type: .ElectronicsItems, title: "electronics".appLocalized, subtitle: "electronics_items".appLocalized),
        ListItemView(type: .CampingItems, title: "camping".appLocalized, subtitle: "camping_essentials".appLocalized),
        ListItemView(type: .ToolsItems, title: "tools".appLocalized, subtitle: "tools_equipment".appLocalized),
        ListItemView(type: .OtherItems, title: "other".appLocalized, subtitle: "other_items".appLocalized)
    ]
}


func getBathroomItems() -> [String] {
    return [
                "antibacterial_hand_gel".appLocalized,
                "moisturizing_wipes".appLocalized,
                "deodorant_perfume".appLocalized,
                "disposable_gloves".appLocalized,
                "cream".appLocalized,
                "mirror".appLocalized,
                "shaving_razor".appLocalized,
                "soap_shampoo".appLocalized,
                "toilet_paper".appLocalized,
                "toothpaste".appLocalized,
                "tweezers".appLocalized,
                "toilet_fluid".appLocalized,
                "portable_shower".appLocalized,
                "towels".appLocalized,
                "dry_shampoo".appLocalized,
                "toothbrush".appLocalized,
                "portable_toilet".appLocalized
    ]}

func getKitchenItems() -> [String] {
    return [
        
    "water_bottle".appLocalized,
    "kettle".appLocalized,
    "cutting_board".appLocalized,
    "pots_pans".appLocalized,
    "trash_can_and_bags".appLocalized,
    "thermos".appLocalized,
    "scissors".appLocalized,
    "wine_and_beer_opener".appLocalized,
    "dish_soap".appLocalized,
    "cooking_utensils".appLocalized,
    "dishcloths_sponges".appLocalized,
    "plates_bowls".appLocalized,
    "travel_mug".appLocalized,
    "coffee_maker".appLocalized,
    "water_containers".appLocalized,
    "insect_repellent".appLocalized,
    "knives_forks_spoons".appLocalized,
    "food_storage_containers".appLocalized
    ]}


func getClothesItems() -> [String] {
    return [
        
        "sweatshirt".appLocalized,
        "long_sleeved_blouse".appLocalized,
        "underwear".appLocalized,
        "trekking_shoes".appLocalized,
        "shower_sandals".appLocalized,
        "shirt".appLocalized,
        "shorts".appLocalized,
        "raincoat".appLocalized,
        "jacket".appLocalized,
        "sunglasses".appLocalized,
        "socks".appLocalized,
        "sweatpants_leggings".appLocalized,
        "skirt".appLocalized,
        "dress".appLocalized,
        "t_shirts".appLocalized,
        "sneakers".appLocalized,
        "regular_pants".appLocalized
    ]}
func getUsefulItems() -> [String] {
    return [
        
        "pen".appLocalized,
        "board_games_playing_cards".appLocalized,
        "blanket".appLocalized,
        "night_lamp".appLocalized,
        "mosquito_net".appLocalized,
        "bedding".appLocalized,
        "pillows_duvet".appLocalized,
        "storage_boxes_baskets".appLocalized,
        "clothespins".appLocalized,
        "clothesline".appLocalized,
        "breakfast_table".appLocalized,
        "favorite_book".appLocalized,
        "earplugs".appLocalized,
        "notebook_journal".appLocalized,
        "window_curtains".appLocalized
    ]}
func getElectronicsItems() -> [String] {
    return [
        "camera".appLocalized,
        "wireless_speaker".appLocalized,
        "gps".appLocalized,
        "usb_cables_chargers".appLocalized,
        "dashcam".appLocalized,
        "laptop_tablet".appLocalized,
        "phone".appLocalized,
        "usb_adapters".appLocalized,
        "spare_batteries".appLocalized,
        "memory_cards".appLocalized,
        "chargers_for_devices".appLocalized
    ]}

func getCampingItems() -> [String] {
    return [
        "hammock_with_attachments".appLocalized,
        "beach_blanket".appLocalized,
        "camping_chairs".appLocalized,
        "sunscreen".appLocalized,
        "flashlight_lamp".appLocalized,
        "tent_and_sleeping_bag".appLocalized,
        "pocket_knife".appLocalized,
        "shovel".appLocalized,
        "axe".appLocalized,
        "mosquito_and_tick_repellent".appLocalized,
        "folding_table".appLocalized
    ]}

func getToolsItems() -> [String] {
    return [
        "additional_water_pump".appLocalized,
        "first_aid_kit".appLocalized,
        "gas_detector".appLocalized,
        "pepper_spray".appLocalized,
        "reflective_vests".appLocalized,
        "jumper_cables".appLocalized,
        "gas_canister".appLocalized,
        "keys".appLocalized,
        "padlock".appLocalized,
        "car_jack".appLocalized,
        "hammer".appLocalized,
        "current_meter".appLocalized,
        "pliers".appLocalized,
        "tire_compressor".appLocalized,
        "protective_gloves".appLocalized,
        "silicone".appLocalized,
        "screwdriver_and_screws".appLocalized,
        "triangle_warning_sign".appLocalized,
        "zip_ties".appLocalized,
        "wd40".appLocalized,
        "spare_oil".appLocalized
    ]}
func getOtherItems() -> [String] {
    return [
        "phone_holder_for_the_car".appLocalized,
        "laundry_basket_bag".appLocalized,
        "needle_thread_safety_pin".appLocalized,
        "dustpan_and_brush".appLocalized,
        "floor_cloth".appLocalized,
        "water_hose".appLocalized,
        "hose_connectors_and_taps".appLocalized,
        "wheel_ramps".appLocalized,
        "plasters_and_bandages".appLocalized,
        "wound_disinfectant".appLocalized,
        "medication_painkillers_antidiarrheals".appLocalized,
        "personal_documents".appLocalized,
        "insurance_ehic_card".appLocalized,
        "drivers_license".appLocalized
    ]}
