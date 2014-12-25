//
//  Level.swift
//  CandyClone
//
//  Created by Edward Oakenfold on 2014-12-13.
//  Copyright (c) 2014 Edward Oakenfold. All rights reserved.
//

import Foundation

// TODO: test coverage
class Level {
    
    var numRow:Int
    var numCol:Int
    
    // together represent layers of game board
    private var candies:[[Candy?]]
    private var tiles:Tiles = Tiles_0() // TODO: load other levels
    
    private var possibleSwaps:[Swap: Bool] = [Swap: Bool]()
    
    init() {
        numRow = tiles.map.count
        numCol = tiles.map[0].count
        
        self.candies = [[Candy?]](count: numRow, repeatedValue: [Candy?](count:numCol, repeatedValue:nil))
    }
    
    func shuffle() -> [Candy?] {
        var pieces:[Candy?] = []
        
        while updatePossibleSwaps() == 0 {
            for row in 0..<numRow {
                for col in 0..<numCol {
                    
                    if tiles.map[row][col] == 1 {
                        
                        var randomType:CandyType
                        var candy:Candy
                        do { // 1. keep generating a random type
                            randomType = CandyType.random()
                            candy = Candy(type: randomType, row: row, col: col)
                        }
                        while (col >= 2 && // 2. if the same type is in the previous 2 columns
                               candies[row][col - 1]?.type == randomType &&
                               candies[row][col - 2]?.type == randomType)
                              ||
                              (row >= 2 && // 3. or previous 2 rows
                               candies[row - 1][col]?.type == randomType &&
                               candies[row - 2][col]?.type == randomType)
                        
                        candies[row][col] = candy // for internal processing
                        pieces.append(candy) // a copy for the client
                    }
                }
            }
        }
        
        return pieces
    }
    
    // either nextRow or nextCol is called with an increment/decrement, but not both simultaneously
    private func possibleSwapNextCandy(row:Int, col:Int, nextRow:Int, nextCol:Int) {
        
        let candy = candies[row][col]!
        
        if let nextCandy = candies[nextRow][nextCol] {
            candies[row][col] = nextCandy
            candies[nextRow][nextCol] = candy
            
            if hasChainAt(nextRow, col: nextCol) {
                possibleSwaps[Swap(fromCandy: nextCandy, toCandy: candy)] = true
            }
            
            // swap them back
            candies[row][col] = candy
            candies[nextRow][nextCol] = nextCandy
        }
    }
    
    func updatePossibleSwaps() -> Int {
        
        possibleSwaps = [Swap: Bool]()
        
        for var row = 0; row < numRow - 1; ++row {
            for var col = 0; col < numCol - 1; ++col {
                if let candy = candies[row][col] {
                    possibleSwapNextCandy(row, col: col, nextRow: row + 1, nextCol: col)
                    possibleSwapNextCandy(row, col: col, nextRow: row, nextCol: col + 1)
                }
            }
        }
        
        // check for swaps in reverse direction
        for var row = numRow - 1; row > 0; --row {
            for var col = numCol - 1; col > 0; --col {
                if let candy = candies[row][col] {
                    possibleSwapNextCandy(row, col: col, nextRow: row - 1, nextCol: col)
                    possibleSwapNextCandy(row, col: col, nextRow: row, nextCol: col - 1)
                }
            }
        }
        
        /*
        println("------------------")
        println("count = \(possibleSwaps.count)")
        println()
        println("possibleSwaps = [")
        for swap in possibleSwaps.keys {
            println("\(swap)")
        }
        println("]")
        println()
        */
        
        return possibleSwaps.count
    }
    
    private func hasChainAt(row:Int, col:Int) -> Bool {
        let candyType = candies[row][col]!.type
        
        var horzCount = 1
        for var i = col - 1; i >= 0 && candies[row][i]?.type == candyType; --i, ++horzCount { }
        for var i = col + 1; i < numCol && candies[row][i]?.type == candyType; ++i, ++horzCount { }
        
        if horzCount >= 3 {
            return true
        }
        
        var vertCount = 1
        for var i = row - 1; i >= 0 && candies[i][col]?.type == candyType; --i, ++vertCount { }
        for var i = row + 1; i < numRow && candies[i][col]?.type == candyType; ++i, ++vertCount { }
        
        return vertCount >= 3
    }
    
    func findChains() -> [[Candy]] {
        var allChains = [[Candy]]()
        var chain = [Candy]()
        var row = 0
        var col = 0
        
        func _findChain() {
            if let candy = candies[row][col] {
                if let lastCandy = chain.last {
                    if lastCandy.type == candy.type {
                        chain.append(candy)
                    }
                    else {
                        if chain.count >= 3 {
                            allChains.append(chain)
                        }
                        chain = [Candy]()
                        chain.append(candy)
                    }
                }
                else {
                    chain.append(candy)
                }
            }
            else {
                if chain.count >= 3 {
                    allChains.append(chain)
                }
                chain = [Candy]()
            }

        }
        
        for row = 0; row < numRow; ++row {
            if chain.count >= 3 {
                allChains.append(chain)
            }
            chain = [Candy]()
            for col = 0; col < numCol; ++col {
                _findChain()
            }
        }
        
        for col = 0; col < numCol; ++col {
            if chain.count >= 3 {
                allChains.append(chain)
            }
            chain = [Candy]()
            for row = 0; row < numRow; ++row {
                _findChain()
            }
        }
        
        return allChains
    }
    
    func removeCandies(chains:[[Candy]]) {
        for chain in chains {
            for candy in chain {
                candies[candy.row][candy.col] = nil
            }
        }
    }
    
    func isNeighbourSwap(swap:Swap) -> Bool {
        
        let fromCandy = swap.a
        let toCandy = swap.b
        
        if fromCandy.row == toCandy.row && fromCandy.col == toCandy.col {
            return false;
        }
        
        if fromCandy.row == toCandy.row {
            if abs(fromCandy.col - toCandy.col) == 1 { // only swap direct neighbour
                return true
            }
        }
        
        if fromCandy.col == toCandy.col {
            if abs(fromCandy.row - toCandy.row) == 1 {
                return true
            }
        }
        
        return false
    }
            
    func isPossibleSwap(swap:Swap) -> Bool {
        return possibleSwaps[swap] != nil
    }
    
    func performSwap(swap:Swap) {
        
        let fromCandy = swap.a
        let toCandy = swap.b
       
        let col = fromCandy.col
        fromCandy.col = toCandy.col
        toCandy.col = col
        
        let row = fromCandy.row
        fromCandy.row = toCandy.row
        toCandy.row = row

        candies[fromCandy.row][fromCandy.col] = fromCandy
        candies[toCandy.row][toCandy.col] = toCandy
    }
    
    func fillHoles() -> [[Candy]] {
        var filler = [[Candy]]()
        
        for col in 0..<numCol {
            var fill = [Candy]()
            for row in 0..<numRow {
                if tiles.map[row][col] != 0 && candies[row][col] == nil {
                    for scanUp in (row + 1)..<numRow {
                        if let candy = candies[scanUp][col] {
                            candies[scanUp][col] = nil
                            candies[row][col] = candy
                            candy.row = row
                            fill.append(candy)
                            break
                        }
                    }
                }
            }
            if fill.count > 0 {
                filler.append(fill)
            }
        }
        
        return filler
    }
    
    func addNewCandies() -> [[Candy]] {
        
        var newCandies = [[Candy]]()
        var lastType:CandyType = .Unknown
        
        for col in 0..<numCol {
            var freshCandies = [Candy]()
            
            for var row = numRow - 1; row >= 0; --row {
                if candies[row][col] != nil {
                    break
                }
                
                if tiles.map[row][col] != 0 {
                    
                    var randomType:CandyType
                    do {
                        randomType = CandyType.random()
                    }
                    while randomType == lastType
                    lastType = randomType
                    
                    let candy = Candy(type: randomType, row: row, col: col)
                    candies[row][col] = candy
                    freshCandies.append(candy)
                }
            }
            
            if freshCandies.count > 0 {
                newCandies.append(freshCandies)
            }
        }
        
        return newCandies
    }
}

protocol Tiles {
    var map:[[Int]] { get }
    var targetScore:Int { get }
    var moves:Int { get}
}

struct Tiles_0 : Tiles {
    let map:[[Int]] = [
        [0, 1, 1, 0, 0, 0, 1, 1, 0 ],
        [1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [0, 0, 1, 1, 1, 1, 1, 0, 0 ],
        [1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [0, 1, 1, 0, 0, 0, 1, 1, 0 ]
    ]
    
    // TODO: support scoring and other features
    let targetScore = 1000
    let moves = 15
}