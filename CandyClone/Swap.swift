//
//  Swap.swift
//  CandyClone
//
//  Created by Edward Oakenfold on 2014-12-14.
//  Copyright (c) 2014 Edward Oakenfold. All rights reserved.
//

import SpriteKit

struct Swap : Printable, Hashable {
    
    var a:Candy
    var b:Candy
    
    init(fromCandy:Candy, toCandy:Candy) {
        self.a = fromCandy
        self.b = toCandy
    }
    
    var hashValue:Int {
        return a.hashValue ^ b.hashValue
    }
    
    var description:String {
        return "swap \(a) with \(b)"
    }
}

func ==(lhs:Swap, rhs:Swap) -> Bool {
    return (lhs.a == rhs.a && lhs.b == rhs.b) ||
           (lhs.a == rhs.b && lhs.b == rhs.a)
}