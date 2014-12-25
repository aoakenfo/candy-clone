//
//  Candy.swift
//  CandyClone
//
//  Created by Edward Oakenfold on 2014-12-13.
//  Copyright (c) 2014 Edward Oakenfold. All rights reserved.
//

import SpriteKit

enum CandyType : Int, Printable, Hashable {
    case Unknown = -1,
    CandyType1,
    CandyType2,
    CandyType3,
    CandyType4,
    CandyType5,
    CandyType6,
    NumCandies
    
    static func random() -> CandyType {
        return CandyType(rawValue: Int(arc4random_uniform(6)))!
    }
    
    var spriteName:String {
        let names = [
            "CandyType1",
            "CandyType2",
            "CandyType3",
            "CandyType4",
            "CandyType5",
            "CandyType6"
        ]
        
        return names[rawValue]
    }
    
    var selectedSpriteName:String {
        let names = [
            "CandyType1-Highlighted",
            "CandyType2-Highlighted",
            "CandyType3-Highlighted",
            "CandyType4-Highlighted",
            "CandyType5-Highlighted",
            "CandyType6-Highlighted"
        ]
        
        return names[rawValue]
    }
    
    var description:String {
        return spriteName;
    }
}

class Candy : Printable {
 
    let type:CandyType
    var row = 0 // carry position into view
    var col = 0
    var sprite:SKSpriteNode?
    
    init(type:CandyType, row:Int, col:Int) {
        self.type = type
        self.row = row
        self.col = col
    }
    
    var description:String {
        return "type:\(type) row:\(row) col:\(col)"
    }
    
    var hashValue:Int {
        return row * 10 + col
    }
}

func ==(lhs:Candy, rhs:Candy) -> Bool {
    return lhs.row == rhs.row && lhs.col == rhs.col
}