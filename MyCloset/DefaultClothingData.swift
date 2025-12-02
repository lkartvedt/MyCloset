//
//  DefaultClothingData.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 12/01/25.
//

import Foundation
import SwiftData

enum DefaultClothingData {
    static func makeItems() -> [ClothingItem] {
        // TOPS
        let greenSweater = ClothingItem(
            name: "Green Sweater",
            category: .tops,
            imageName: "green_sweater",
            tags: ["turtle neck", "fall", "winter", "green", "polyester"]
        )
        let blackCrop = ClothingItem(
            name: "Black Crop Top",
            category: .tops,
            imageName: "black_crop",
            tags: ["mock turtle neck", "black", "crop top"]
        )
        let grayTank = ClothingItem(
            name: "Gray Crop Tank",
            category: .tops,
            imageName: "gray_tank",
            tags: ["velvet", "tank top", "crop top", "gray"]
        )
        let greenTank = ClothingItem(
            name: "Green Crop Tank",
            category: .tops,
            imageName: "green_tank",
            tags: ["velvet", "tank top", "crop top", "green"]
        )

        // BOTTOMS
            // PANTS
        let jeans = ClothingItem(
            name: "Jeans",
            category: .bottoms,
            subcategory: .pants,
            imageName: "jeans",
            tags: ["denim", "light blue", "pacsun", "high waisted"]
        )
            // SHORT SKIRTS
        let blackSkort = ClothingItem(
            name: "Black Skort",
            category: .bottoms,
            subcategory: .short_skirts,
            imageName: "black_skort",
            tags: ["black", "skort", "gold", "mini skirt"]
        )
            // LONG SKIRTS
        let pinkCheetahSkirt = ClothingItem(
            name: "Cheetah Skirt",
            category: .bottoms,
            subcategory: .long_skirts,
            imageName: "pink_cheetah",
            tags: ["pink", "long skirt", "cheetah print", "shimmery"]
        )
        let leopardSkirt = ClothingItem(
            name: "Leopard Skirt",
            category: .bottoms,
            subcategory: .long_skirts,
            imageName: "leopard",
            tags: ["tan", "black", "long skirt", "leopard print", "slit"]
        )

        // UNDERGARMENTS – TIGHTS
        let blackTights = ClothingItem(
            name: "Black Sheer Tights",
            category: .undergarments,
            subcategory: .tights,
            imageNameFlat: "black_sheer_flat",
            imageNameHeels: "black_sheer_heels",
            tags: ["tights", "winter", "fall", "black"],
            supportedFootStyles: [.flat, .heels]
        )
        let polkadotTights = ClothingItem(
            name: "Polkadot Tights",
            category: .undergarments,
            subcategory: .tights,
            imageNameFlat: "polkadot_flat",
            imageNameHeels: "polkadot_heels",
            tags: ["tights", "winter", "fall", "black"],
            supportedFootStyles: [.flat, .heels]
        )
        let maroonTights = ClothingItem(
            name: "Maroon Tights",
            category: .undergarments,
            subcategory: .tights,
            imageNameFlat: "maroon_flat",
            imageNameHeels: "maroon_heels",
            tags: ["tights", "winter", "fall", "maroon"],
            supportedFootStyles: [.flat, .heels]
        )
        let navyPlaidTights = ClothingItem(
            name: "Navy Plaid Tights",
            category: .undergarments,
            subcategory: .tights,
            imageNameFlat: "navy_plaid_flat",
            imageNameHeels: "navy_plaid_heels",
            tags: ["tights", "winter", "fall", "navy", "plaid"],
            supportedFootStyles: [.flat, .heels]
        )
        let fleeceTights = ClothingItem(
            name: "Fleece Tights",
            category: .undergarments,
            subcategory: .tights,
            imageNameFlat: "fleece_flat",
            imageNameHeels: "fleece_heels",
            tags: ["tights", "winter", "fall", "peach", "tan", "fleece"],
            supportedFootStyles: [.flat, .heels]
        )

        // SHOES
        let sneakers = ClothingItem(
            name: "White Sneakers",
            category: .shoes,
            imageName: "white_tennis_shoes",
            tags: ["casual"],
            supportedFootStyles: [.flat]
        )
        let tallBlackBoots = ClothingItem(
            name: "Tall Black Boots",
            category: .shoes,
            imageName: "black_boots",
            tags: ["black", "leather", "winter", "fall", "knee high", "boots"],
            supportedFootStyles: [.heels]
        )
        let grayUggs = ClothingItem(
            name: "Gray Uggs",
            category: .shoes,
            imageName: "gray_uggs",
            tags: ["gray", "boots", "winter", "fall"],
            supportedFootStyles: [.flat]
        )

        return [
            greenSweater, blackCrop, grayTank, greenTank,
            jeans, blackSkort, pinkCheetahSkirt, leopardSkirt,
            blackTights, polkadotTights, maroonTights, navyPlaidTights, fleeceTights,
            sneakers, tallBlackBoots, grayUggs
        ]
    }
}
