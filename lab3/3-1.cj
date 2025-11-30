import std.collection.*

// 左递归消除器类
class LRE {
    public var cfg: ArrayList<(String, ArrayList<String>)> = ArrayList<(String, ArrayList<String>)>()
    public var notend: ArrayList<String> = ArrayList<String>()

    // 从内置字符串读取上下文无关文法
    public func readCFG(content: String): Unit {
        let lines = content.split('\n')
        
        let spaceChar: UInt8 = ' '
        let tabChar: UInt8 = '\t'
        let crChar: UInt8 = '\r'
        let hashChar: UInt8 = '#'
        
        for (line in lines) {
            // 去除前后空白
            var trimmedLine = line
            while (!trimmedLine.isEmpty() && (trimmedLine[0] == spaceChar || trimmedLine[0] == tabChar || trimmedLine[0] == crChar)) {
                trimmedLine = trimmedLine[1..]
            }
            while (!trimmedLine.isEmpty() && (trimmedLine[trimmedLine.size - 1] == spaceChar || trimmedLine[trimmedLine.size - 1] == tabChar || trimmedLine[trimmedLine.size - 1] == crChar)) {
                trimmedLine = trimmedLine[0..(trimmedLine.size - 1)]
            }
            
            // 忽略空行或以 '#' 开头的注释行
            if (trimmedLine.isEmpty() || trimmedLine[0] == hashChar) {
                continue
            }
            
            // 使用 -> 分割
            let arrowParts = trimmedLine.split("->")
            if (arrowParts.size < 2) {
                continue
            }
            
            var nonTerminal = arrowParts[0]
            // 去除非终结符前后空白
            while (!nonTerminal.isEmpty() && (nonTerminal[0] == spaceChar || nonTerminal[0] == tabChar)) {
                nonTerminal = nonTerminal[1..]
            }
            while (!nonTerminal.isEmpty() && (nonTerminal[nonTerminal.size - 1] == spaceChar || nonTerminal[nonTerminal.size - 1] == tabChar)) {
                nonTerminal = nonTerminal[0..(nonTerminal.size - 1)]
            }
            
            var productionStr = arrowParts[1]
            // 去除生产式前后空白
            while (!productionStr.isEmpty() && (productionStr[0] == spaceChar || productionStr[0] == tabChar)) {
                productionStr = productionStr[1..]
            }
            while (!productionStr.isEmpty() && (productionStr[productionStr.size - 1] == spaceChar || productionStr[productionStr.size - 1] == tabChar)) {
                productionStr = productionStr[0..(productionStr.size - 1)]
            }
            
            let productionParts = productionStr.split('|')
            
            let productions = ArrayList<String>()
            for (prod in productionParts) {
                // 手动去除前后空白
                var trimmedProd = prod
                while (!trimmedProd.isEmpty() && (trimmedProd[0] == spaceChar || trimmedProd[0] == tabChar)) {
                    trimmedProd = trimmedProd[1..]
                }
                while (!trimmedProd.isEmpty() && (trimmedProd[trimmedProd.size - 1] == spaceChar || trimmedProd[trimmedProd.size - 1] == tabChar)) {
                    trimmedProd = trimmedProd[0..(trimmedProd.size - 1)]
                }
                if (!trimmedProd.isEmpty()) {
                    productions.add(trimmedProd)
                }
            }
            
            // 检查非终结符是否已存在
            var found = false
            for (i in 0..cfg.size) {
                let (nt, prods) = cfg[i]
                if (nt == nonTerminal) {
                    for (prod in productions) {
                        prods.add(prod)
                    }
                    found = true
                    break
                }
            }
            
            if (!found) {
                cfg.add((nonTerminal, productions))
                notend.add(nonTerminal)
            }
        }
    }

    // 打印上下文无关文法
    public func printCFG(): Unit {
        for (rule in cfg) {
            let (nonTerminal, productions) = rule
            print("  ${nonTerminal} -> ")
            
            var first = true
            for (prod in productions) {
                if (!first) {
                    print(" | ")
                }
                print(prod)
                first = false
            }
            println("")
        }
    }

    // 消除间接左递归
    public func eliminateIndirectLeftRecursion(): Unit {
        for (i in 0..notend.size) {
            let A = notend[i]
            
            // 找到 A 在 cfg 中的位置
            var posA = -1
            for (k in 0..cfg.size) {
                let (nt, _) = cfg[k]
                if (nt == A) {
                    posA = k
                    break
                }
            }
            
            if (posA == -1) {
                continue
            }
            
            // 遍历前面的非终结符
            for (j in 0..i) {
                let B = notend[j]
                
                // 找到 B 在 cfg 中的位置
                var posB = -1
                for (k in 0..cfg.size) {
                    let (nt, _) = cfg[k]
                    if (nt == B) {
                        posB = k
                        break
                    }
                }
                
                if (posB == -1) {
                    continue
                }
                
                let (_, AProductions) = cfg[posA]
                let (_, BProductions) = cfg[posB]
                
                let newProductions = ArrayList<String>()
                
                for (production in AProductions) {
                    if (production.startsWith(B)) {
                        // 用 B 的候选式替换 B
                        for (bProd in BProductions) {
                            let remaining = production[B.size..]
                            newProductions.add(bProd + remaining)
                        }
                    } else {
                        newProductions.add(production)
                    }
                }
                
                // 更新 A 的产生式
                AProductions.clear()
                for (prod in newProductions) {
                    AProductions.add(prod)
                }
            }
        }
    }

    // 消除直接左递归
    public func eliminateDirectLeftRecursion(): Unit {
        var i = 0
        
        while (i < cfg.size) {
            let (A, productions) = cfg[i]
            
            let alphaRules = ArrayList<String>()
            let betaRules = ArrayList<String>()
            
            // 分类候选式
            for (production in productions) {
                if (production.startsWith(A)) {
                    // 直接左递归部分
                    alphaRules.add(production[A.size..])
                } else {
                    // 非直接左递归部分
                    betaRules.add(production)
                }
            }
            
            if (!alphaRules.isEmpty()) {
                // 存在直接左递归
                let APrime = A + "'"
                
                // A -> βA'
                productions.clear()
                for (beta in betaRules) {
                    productions.add(beta + APrime)
                }
                
                // A' -> αA' | ε
                let newProductions = ArrayList<String>()
                for (alpha in alphaRules) {
                    newProductions.add(alpha + APrime)
                }
                newProductions.add("ε")
                
                // 手动插入到指定位置
                let tempCfg = ArrayList<(String, ArrayList<String>)>()
                let tempNotend = ArrayList<String>()
                
                // 复制前面的元素
                for (j in 0..(i + 1)) {
                    tempCfg.add(cfg[j])
                    tempNotend.add(notend[j])
                }
                
                // 插入新元素
                tempCfg.add((APrime, newProductions))
                tempNotend.add(APrime)
                
                // 复制后面的元素
                for (j in (i + 1)..cfg.size) {
                    tempCfg.add(cfg[j])
                    tempNotend.add(notend[j])
                }
                
                // 更新 cfg 和 notend
                cfg = tempCfg
                notend = tempNotend
                
                i += 2  // 跳过新插入的非终结符
            } else {
                i += 1
            }
        }
    }

    // 消除所有左递归
    public func eliminateLeftRecursion(): Unit {
        // 先消除间接左递归
        eliminateIndirectLeftRecursion()
        
        // 再消除直接左递归
        eliminateDirectLeftRecursion()
    }
}

// 主函数
main() {
    // 内置的文法字符串
    let grammarContent = """
S -> S+T | T
T -> T*F | F
F -> (E) | id
"""
    
    println("原始文法:")
    let lre = LRE()
    lre.readCFG(grammarContent)
    lre.printCFG()
    println("")
    
    // 消除左递归
    lre.eliminateLeftRecursion()
    
    // 打印消除左递归后的文法
    println("消除左递归后的文法:")
    lre.printCFG()
}