import std.collection.*

// Trie 树节点类
class TrieNode {
    public var children: HashMap<UInt8, TrieNode> = HashMap<UInt8, TrieNode>()
    public var isEndOfWord: Bool = false
    
    public init() {}
}

// Trie 树类
class Trie {
    private var root: TrieNode = TrieNode()
    
    public init() {}
    
    // 插入一个候选式到 Trie 树中
    public func insert(word: String): Unit {
        var node = root
        for (char in word) {
            if (!node.children.contains(char)) {
                node.children[char] = TrieNode()
            }
            node = node.children[char]
        }
        node.isEndOfWord = true
    }
    
    // 获取 Trie 树中的最长公共前缀
    public func longestCommonPrefix(): String {
        var prefix = ""
        var node = root
        while (node.children.size == 1) {
            let entry = node.children.iterator().next()
            if (entry.isSome()) {
                let (char, nextNode) = entry.getOrThrow()
                // 将UInt8转换为String - 使用子字符串
                let tempStr = " "
                for (i in 0..1) {
                    // 通过遍历单字符字符串来获取
                    var found = false
                    for (c in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()+-*/ ") {
                        if (c == char) {
                            // 找到匹配的字符,构建字符串
                            let bytes = ArrayList<UInt8>()
                            bytes.add(char)
                            // 简单处理:直接用索引构建
                            prefix = prefix + tempStr[0..1]
                            found = true
                            break
                        }
                    }
                    if (!found) {
                        // 如果没找到,使用通用方法
                        prefix = prefix + " "
                    }
                    break
                }
                node = nextNode
            } else {
                break
            }
        }
        return prefix
    }
    
    // 用候选式列表构建 Trie 树
    public func buildTrie(strings: ArrayList<String>): Unit {
        for (str in strings) {
            insert(str)
        }
    }
}

// UInt8转String的辅助函数
func uint8ToString(char: UInt8): String {
    // 为常见字符创建映射
    let charA: UInt8 = 'a'
    let charZ: UInt8 = 'z'
    let charAUpper: UInt8 = 'A'
    let charZUpper: UInt8 = 'Z'
    let char0: UInt8 = '0'
    let char9: UInt8 = '9'
    let charSpace: UInt8 = ' '
    let charPlus: UInt8 = '+'
    let charMinus: UInt8 = '-'
    let charStar: UInt8 = '*'
    let charSlash: UInt8 = '/'
    let charLParen: UInt8 = '('
    let charRParen: UInt8 = ')'
    
    if (char >= charA && char <= charZ) {
        let offset = char - charA
        return "abcdefghijklmnopqrstuvwxyz"[Int64(offset)..Int64(offset + 1)]
    } else if (char >= charAUpper && char <= charZUpper) {
        let offset = char - charAUpper
        return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[Int64(offset)..Int64(offset + 1)]
    } else if (char >= char0 && char <= char9) {
        let offset = char - char0
        return "0123456789"[Int64(offset)..Int64(offset + 1)]
    } else if (char == charSpace) {
        return " "
    } else if (char == charPlus) {
        return "+"
    } else if (char == charMinus) {
        return "-"
    } else if (char == charStar) {
        return "*"
    } else if (char == charSlash) {
        return "/"
    } else if (char == charLParen) {
        return "("
    } else if (char == charRParen) {
        return ")"
    }
    
    return " " // 默认返回空格
}

// 文法类
class Grammar {
    public var nonTerminals: ArrayList<String> = ArrayList<String>()
    public var terminals: ArrayList<String> = ArrayList<String>()
    public var productions: HashMap<String, ArrayList<String>> = HashMap<String, ArrayList<String>>()
    
    public init() {}
    
    // 为非终结符添加候选式
    public func addProduction(nonTerminal: String, production: String): Unit {
        if (!productions.contains(nonTerminal)) {
            productions[nonTerminal] = ArrayList<String>()
        }
        let prods = productions[nonTerminal]
        prods.add(production)
    }
    
    // 添加非终结符
    public func addNonTerminal(nonTerminal: String): Unit {
        if (!nonTerminals.contains(nonTerminal)) {
            nonTerminals.add(nonTerminal)
        }
    }
    
    // 添加终结符
    public func addTerminal(terminal: String): Unit {
        if (!terminals.contains(terminal)) {
            terminals.add(terminal)
        }
    }
    
    // 打印文法规则
    public func display(): Unit {
        for (nonTerminal in nonTerminals) {
            let prodsOpt = productions.get(nonTerminal)
            if (prodsOpt.isSome()) {
                let prods = prodsOpt.getOrThrow()
                print("  ${nonTerminal} -> ")
                
                var first = true
                for (prod in prods) {
                    if (!first) {
                        print(" | ")
                    }
                    print(prod)
                    first = false
                }
                println("")
            }
        }
    }
}

// 提取左公共因子
func extractLeftCommonFactor(grammar: Grammar): Grammar {
    let newGrammar = Grammar()
    
    // 复制非终结符和终结符
    for (nt in grammar.nonTerminals) {
        newGrammar.nonTerminals.add(nt)
    }
    for (t in grammar.terminals) {
        newGrammar.terminals.add(t)
    }
    
    // 查找最长公共前缀 - 简化版本
    func findLongestCommonPrefix(strings: ArrayList<String>): String {
        if (strings.isEmpty() || strings.size == 1) {
            return ""
        }
        
        let first = strings[0]
        var prefixLen = 0
        
        for (i in 0..first.size) {
            var allMatch = true
            for (j in 1..strings.size) {
                let str = strings[j]
                if (i >= str.size || str[i] != first[i]) {
                    allMatch = false
                    break
                }
            }
            if (allMatch) {
                prefixLen = i + 1
            } else {
                break
            }
        }
        
        if (prefixLen > 0) {
            return first[0..prefixLen]
        }
        return ""
    }
    
    // 按前缀分组
    func groupByPrefix(productions: ArrayList<String>): HashMap<UInt8, ArrayList<String>> {
        let groups = HashMap<UInt8, ArrayList<String>>()
        let spaceChar: UInt8 = ' '
        
        for (prod in productions) {
            let prefix: UInt8 = if (!prod.isEmpty()) { prod[0] } else { spaceChar }
            if (!groups.contains(prefix)) {
                groups[prefix] = ArrayList<String>()
            }
            groups[prefix].add(prod)
        }
        return groups
    }
    
    // 处理一个非终结符的候选式
    func processNonTerminal(nonTerminal: String): Unit {
        let prodsOpt = grammar.productions.get(nonTerminal)
        if (prodsOpt.isNone()) {
            return
        }
        
        let productions = prodsOpt.getOrThrow()
        var suffixCounter = 1
        
        // 按照第一个字符分组
        let groups = groupByPrefix(productions)
        
        let processedGroups = ArrayList<String>()
        
        // 处理每个组
        for ((prefix, groupProductions) in groups) {
            if (groupProductions.size == 1) {
                processedGroups.add(groupProductions[0])
                continue
            }
            
            // 对于多个产生式,提取公共前缀
            let commonPrefix = findLongestCommonPrefix(groupProductions)
            if (!commonPrefix.isEmpty()) {
                // 创建新非终结符
                var newNonTerminal = nonTerminal
                for (_ in 0..suffixCounter) {
                    newNonTerminal = newNonTerminal + "'"
                }
                
                while (newGrammar.nonTerminals.contains(newNonTerminal)) {
                    suffixCounter++
                    newNonTerminal = nonTerminal
                    for (_ in 0..suffixCounter) {
                        newNonTerminal = newNonTerminal + "'"
                    }
                }
                
                newGrammar.addNonTerminal(newNonTerminal)
                
                // 添加公共前缀的规则
                processedGroups.add(commonPrefix + newNonTerminal)
                
                // 将剩余部分添加到新非终结符
                for (prod in groupProductions) {
                    let suffix = if (prod.size > commonPrefix.size) {
                        prod[commonPrefix.size..]
                    } else {
                        "ε"
                    }
                    newGrammar.addProduction(newNonTerminal, suffix)
                }
            } else {
                for (prod in groupProductions) {
                    processedGroups.add(prod)
                }
            }
        }
        
        // 将处理后的产生式添加到新文法中
        for (prod in processedGroups) {
            newGrammar.addProduction(nonTerminal, prod)
        }
    }
    
    // 对每个非终结符进行处理
    for (nonTerminal in grammar.nonTerminals) {
        processNonTerminal(nonTerminal)
    }
    
    return newGrammar
}

// 从字符串输入文法
func inputGrammarFromString(content: String): Grammar {
    let grammar = Grammar()
    let lines = content.split('\n')
    
    let spaceChar: UInt8 = ' '
    let tabChar: UInt8 = '\t'
    let crChar: UInt8 = '\r'
    
    for (line in lines) {
        // 去除前后空白
        var trimmedLine = line
        while (!trimmedLine.isEmpty() && (trimmedLine[0] == spaceChar || trimmedLine[0] == tabChar || trimmedLine[0] == crChar)) {
            trimmedLine = trimmedLine[1..]
        }
        while (!trimmedLine.isEmpty() && (trimmedLine[trimmedLine.size - 1] == spaceChar || trimmedLine[trimmedLine.size - 1] == tabChar || trimmedLine[trimmedLine.size - 1] == crChar)) {
            trimmedLine = trimmedLine[0..(trimmedLine.size - 1)]
        }
        
        if (trimmedLine.isEmpty()) {
            continue
        }
        
        // 使用 -> 分割
        let arrowParts = trimmedLine.split("->")
        if (arrowParts.size < 2) {
            continue
        }
        
        var left = arrowParts[0]
        // 去除空白
        while (!left.isEmpty() && (left[0] == spaceChar || left[0] == tabChar)) {
            left = left[1..]
        }
        while (!left.isEmpty() && (left[left.size - 1] == spaceChar || left[left.size - 1] == tabChar)) {
            left = left[0..(left.size - 1)]
        }
        
        grammar.addNonTerminal(left)
        
        var right = arrowParts[1]
        // 去除空白
        while (!right.isEmpty() && (right[0] == spaceChar || right[0] == tabChar)) {
            right = right[1..]
        }
        while (!right.isEmpty() && (right[right.size - 1] == spaceChar || right[right.size - 1] == tabChar)) {
            right = right[0..(right.size - 1)]
        }
        
        let productions = right.split('|')
        for (prod in productions) {
            var trimmedProd = prod
            while (!trimmedProd.isEmpty() && (trimmedProd[0] == spaceChar || trimmedProd[0] == tabChar)) {
                trimmedProd = trimmedProd[1..]
            }
            while (!trimmedProd.isEmpty() && (trimmedProd[trimmedProd.size - 1] == spaceChar || trimmedProd[trimmedProd.size - 1] == tabChar)) {
                trimmedProd = trimmedProd[0..(trimmedProd.size - 1)]
            }
            
            if (!trimmedProd.isEmpty()) {
                grammar.addProduction(left, trimmedProd)
                
                // 识别终结符
                let charA: UInt8 = 'A'
                let charZ: UInt8 = 'Z'
                for (char in trimmedProd) {
                    // 检查不是大写字母
                    if (!(char >= charA && char <= charZ)) {
                        let charStr = uint8ToString(char)
                        if (charStr != "ε" && charStr != " ") {
                            grammar.addTerminal(charStr)
                        }
                    }
                }
            }
        }
    }
    
    return grammar
}

// 主函数
main() {
    // 内置的文法字符串
    let grammarContent = """
    S -> apple | apply | application | ball | bat | bath | Xb
    X -> ab | ac | a
    """
    
    println("原始文法:")
    let grammar = inputGrammarFromString(grammarContent)
    grammar.display()
    println("")
    
    // 提取左公共因子
    let noCommonFactorGrammar = extractLeftCommonFactor(grammar)
    
    println("提取左公共因子后的文法:")
    noCommonFactorGrammar.display()
}