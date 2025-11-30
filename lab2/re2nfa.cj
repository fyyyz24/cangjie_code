package RegExp_NFA_DFA
import std.collection.*
import std.fs.*

struct FAnode {
    var node = Array(27, {_ => ArrayList<Int64>()})
}

// 泛型栈，用于中缀转后缀存储字符；用于 Thompson 存储状态节点
struct Stack<T> {
    var elements = ArrayList<T>()

    // 入栈
    func push(e: T) {
        elements.add(e)
    }

    // 出栈
    func pop(): T {
        let lastIndex = elements.size - 1
        let value = elements[lastIndex]
        // ArrayList.remove 需要 Range<Int64>，这里删除 [lastIndex, lastIndex+1)
        elements.remove(lastIndex..(lastIndex + 1))
        return value
    }

    // 判断是否为空
    func isEmpty(): Bool {
        if (elements.size == 0) {
            return true
        } else {
            return false
        }
    }

    // 查看栈顶元素
    func top(): T {
        return elements[elements.size - 1]
    }
}

var nfa = ArrayList<FAnode>()
var len: Int64 = 0
var s: Stack<Int64> = Stack()

var dfa = ArrayList<FAnode>()
// DFA 状态子集总个数（当前最大下标）
var p: Int64 = 0
var Dstates = ArrayList<HashSet<Int64>>() // 状态子集

// 用 '+' 表示连接运算
func Add_symbol(regexp: String): String {
    var regexp2: String = ""
    var c1: Rune
    var c2: Rune
    var i: Int64 = 0
    while (i < regexp.size - 1) {
        c1 = Rune(regexp[i])
        c2 = Rune(regexp[i + 1])
        regexp2 += String(c1)
        if (c1 != r'(' && c2 != r')' && c1 != r'|' && c2 != r'|' && c2 != r'*') {
            regexp2 += '+'
        }
        i++
    }
    regexp2 += String(Rune(regexp[regexp.size - 1]))
    return regexp2
}

// 定义优先级
func Priority(ch: String): Int8 {
    if (ch == "*") { return 3 }
    else if (ch == "+") { return 2 }
    else if (ch == "|") { return 1 }
    else { return 0 }
}

// 加工后的正规式转为后缀表达式
func RegExp_to_Postfix(regexp2: String): String {
    var postfix: String = ""
    var s2: Stack<String> = Stack()
    var ch: String
    for (i in regexp2) {
        ch = String(Rune(i))
        if (ch <= "z" && ch >= "a") { postfix += ch }
        else if (ch == "(") { s2.push(ch) }
        else if (ch == ")") {
            while (s2.top() != "(") {
                postfix += s2.pop()
            }
            s2.pop()
        } else {
            while (!s2.isEmpty()) {
                if (Priority(s2.top()) >= Priority(ch)) {
                    postfix += s2.pop()
                } else { break }
            }
            s2.push(ch)
        }
    }
    // 检查栈里是否还有剩余元素
    while (!s2.isEmpty()) {
        postfix += s2.pop()
    }
    return postfix
}

// 分配空间：一次分两个新状态
func Get_are() {
    var newnode: FAnode = FAnode()
    var newnode2: FAnode = FAnode()
    nfa.add(newnode)
    nfa.add(newnode2)
}

// 处理 a 或 b
func Do_ab(i: Int64) {
    Get_are()
    nfa[len].node[i].add(len + 1)
    s.push(len)
    s.push(len + 1)
    len += 2
}

// 处理 '*'
func Do_star() {
    var b: Int64 = s.pop()
    var a: Int64 = s.pop()
    Get_are()
    nfa[b].node[0].add(a)
    nfa[len].node[0].add(a)
    nfa[len].node[0].add(len + 1)
    nfa[b].node[0].add(len + 1)
    s.push(len)
    s.push(len + 1)
    len += 2
}

// 处理 '|'
func Do_or() {
    var a: Int64 = s.pop()
    var b: Int64 = s.pop()
    var c: Int64 = s.pop()
    var d: Int64 = s.pop()
    Get_are()
    nfa[a].node[0].add(len + 1)
    nfa[len].node[0].add(b)
    nfa[c].node[0].add(len + 1)
    nfa[len].node[0].add(d)
    s.push(len)
    s.push(len + 1)
    len += 2
}

// 处理 '+'
func Do_add() {
    var d: Int64 = s.pop()
    var b: Int64 = s.pop()
    var a: Int64 = s.pop()
    var c: Int64 = s.pop()
    nfa[a].node[0].add(b)
    s.push(c)
    s.push(d)
}

// 后缀表达式转为 NFA（Thompson 构造法）
func Postfix_to_NFA(postfix: String) {
    var ch: String
    for (i in postfix) {
        ch = String(Rune(i))
        if (ch <= "z" && ch >= "a") {
            Do_ab(Int64(i) - 97 + 1)
        } else if (ch == "*") {
            Do_star()
        } else if (ch == "+") {
            Do_add()
        } else if (ch == "|") {
            Do_or()
        } else {
            println("输入非法字符")
        }
    }
}

// 得到开始状态 q0：没有入度的状态
func Get_q0(): Int64 {
    var flag: Bool
    var q0: Int64 = -1
    for (k in 0..len) {
        flag = true
        for (i in 0..len) {
            for (j in 0..=26) {
                if (nfa[i].node[j].contains(k)) {
                    flag = false
                    break
                }
            }
        }
        if (flag) {
            q0 = k
            break
        }
    }
    return q0
}

// 得到接收状态集 F：没有出度的状态
func Get_F(): ArrayList<Int64> {
    var arr = ArrayList<Int64>()
    var flag: Bool
    for (i in 0..len) {
        flag = true
        for (j in 0..=26) {
            if (nfa[i].node[j].size != 0) {
                flag = false
                break
            }
        }
        if (flag) {
            arr.add(i)
        }
    }
    return arr
}

// 得到输入符号集合 Σ
func Get_ab(): HashSet<Int64> {
    var arr = HashSet<Int64>()
    for (i in 0..len) {
        for (j in 1..=26) {
            if (nfa[i].node[j].size > 0) {
                arr.add(j)
            }
        }
    }
    return arr
}

// 计算 NFA 并打印
func Print_NFA(regexp: String) {
    var count: Int64 = 0
    println("正规式：" + regexp)
    var regexp2 = Add_symbol(regexp)
    println("加工后的正规式：" + regexp2)
    var postfix = RegExp_to_Postfix(regexp2)
    println("后缀表达式：" + postfix)
    Postfix_to_NFA(postfix)
    println("NFA：")
    // 打印状态集 Q
    print("Q = {")
    for (i in 0..len) {
        if (i == len - 1) { println("${i}}") }
        else { print("${i}, ") }
    }
    // 打印输入符号集合 Σ
    print("Σ = {")
    var ab = Get_ab()
    for (i in ab) {
        if (count == ab.size - 1) { println("${Rune(i + 96)}}") }
        else { print("${Rune(i + 96)}, ") }
        count++
    }
    // 打印状态转换函数 δ, ε
    print("δ = {")
    for (i in 0..len) {
        for (j in 0..=26) {
            if (nfa[i].node[j].size > 0) {
                var str: String = ""
                for (value in nfa[i].node[j]) {
                    str += "${value},"
                }
                if (j == 0) { print("δ(${i},ε)={${str}}, ") }
                else { print("δ(${i},${Rune(j + 96)})={${str}}, ") }
            }
        }
    }
    println("}")
    // 打印开始状态
    println("q0 = {${Get_q0()}}")
    // 打印接收状态集合
    print("F = {")
    var arr = Get_F()
    for (i in arr) {
        if (i == arr[arr.size - 1]) { print(i) }
        else { print("${i}, ") }
    }
    println("}")
}

// 求状态 t 的 ε-闭包
func E_closure(t: Int64): HashSet<Int64> {
    var I = HashSet<Int64>()
    I.add(t)
    for (j in nfa[t].node[0]) {
        if (!I.contains(j)) {
            I.add(j)
            let sub = E_closure(j)
            for (x in sub) {
                I.add(x)
            }
        }
    }
    return I
}

// 求状态子集 I 的 ε-闭包
func E_closure(I: HashSet<Int64>): HashSet<Int64> {
    var I2 = HashSet<Int64>()
    for (i in I) {
        let sub = E_closure(i)
        for (x in sub) {
            I2.add(x)
        }
    }
    return I2
}

// 状态 t 的 a 边转换，不包括状态 t 自身
func Edge(t: Int64, a: Int64): HashSet<Int64> {
    var I = HashSet<Int64>()
    for (j in nfa[t].node[a]) {
        if (!I.contains(j)) {
            I.add(j)
            let sub = Edge(j, a)
            for (x in sub) {
                I.add(x)
            }
        }
    }
    return I
}

// 状态集 I 的 a 边转换
func Edge(I: HashSet<Int64>, a: Int64): HashSet<Int64> {
    var J = HashSet<Int64>()
    for (t in I) {
        let sub = Edge(t, a)
        for (x in sub) {
            J.add(x)
        }
    }
    return J
}

// 状态子集 I 的 a 边转换并取 ε-闭包
func DFA_edge(I: HashSet<Int64>, a: Int64): HashSet<Int64> {
    return E_closure(Edge(I, a))
}

// NFA 转 DFA（子集构造法 Subset Construction）
func NFA_to_DFA() {
    // 第一个状态子集是 NFA 开始状态的 ε-闭包
    var startSet = E_closure(Get_q0())
    Dstates.add(startSet)
    dfa.add(FAnode())   // 对应 DFA 的状态 0
    p = 0

    var j: Int64 = 0
    var ab = Get_ab()

    while (j <= p) {
        for (a in ab) {
            var e = DFA_edge(Dstates[j], a)
            if (e.size == 0) {
                continue
            }
            var idx: Int64 = -1
            // 判断是否是已有的状态子集
            for (k in 0..=p) {
                if (Dstates[k] == e) {
                    idx = k
                    break
                }
            }
            // 若不存在，则添加新状态子集
            if (idx == -1) {
                p++
                Dstates.add(e)
                dfa.add(FAnode())
                idx = p
            }
            // 建立 j --a--> idx
            dfa[j].node[a - 1].add(idx)
        }
        j++
    }
}

// 打印 DFA
func Print_DFA() {
    var count: Int64 = 0
    println("DFA:")
    // 打印状态集 Q
    print("Q = {")
    for (i in 0..=p) {
        if (i == p) { println("${i}}") }
        else { print("${i}, ") }
    }
    // 打印输入符号集合 Σ
    print("Σ = {")
    var ab = Get_ab()
    for (a in ab) {
        if (count == ab.size - 1) { println("${Rune(a + 96)}}") }
        else { print("${Rune(a + 96)}, ") }
        count++
    }
    // 打印状态转换函数 δ
    print("δ = {")
    for (i in 0..=p) {
        for (a in ab) {
            if (dfa[i].node[a - 1].size > 0) {
                var str: String = ""
                for (value in dfa[i].node[a - 1]) {
                    str += "${value},"
                }
                print("δ(${i},${Rune(a + 96)})={${str}}, ")
            }
        }
    }
    println("}")
    // 打印开始状态
    println("q0 = {0}")
    // 打印接收状态集合
    var F = HashSet<Int64>()
    print("F = {")
    var arr = Get_F()
    for (i in arr) {
        for (j in 0..=p) {
            if (Dstates[j].contains(i)) {
                F.add(j)
            }
        }
    }
    var F_count: Int64 = 0
    for (i in F) {
        F_count++
        if (F_count == F.size) { println("${i}}") }
        else { print("${i}, ") }
    }
}

// 生成 NFA 的 DOT 文件
func Export_NFA_Dot(filename: String) {

    var sb: String = "digraph NFA {\n"
    sb += "    rankdir=LR;\n"
    sb += "    node [shape=circle];\n"

    // 开始状态
    let start = Get_q0()
    sb += "    start [shape=point];\n"
    sb += "    start -> ${start};\n"

    // 接收状态
    let F = Get_F()
    for (f in F) {
        sb += "    ${f} [shape=doublecircle];\n"
    }

    // 边
    for (i in 0..len) {
        for (j in 0..=26) {
            if (nfa[i].node[j].size > 0) {
                var label: String
                if (j == 0) {
                    label = "ε"
                }
                else {
                    label = String(Rune(j + 96))
                }
                for (dst in nfa[i].node[j]) {
                    sb += "    ${i} -> ${dst} [label=\"${label}\"];\n"
                }
            }
        }
    }

    sb += "}\n"

    let file = File(Path(filename), OpenMode.Write)
    file.write(sb.toArray())
    file.close()
    println("NFA 的 dot 文件已写入: " + filename)
}

func Export_DFA_Dot(filename: String) {

    var sb: String = "digraph DFA {\n"
    sb += "    rankdir=LR;\n"
    sb += "    node [shape=circle];\n"

    sb += "    start [shape=point];\n"
    sb += "    start -> 0;\n"

    // 接收状态
    let NFA_F = Get_F()
    var DFA_F = HashSet<Int64>()
    for (i in NFA_F) {
        for (j in 0..=p) {
            if (Dstates[j].contains(i)) {
                DFA_F.add(j)
            }
        }
    }

    for (f in DFA_F) {
        sb += "    ${f} [shape=doublecircle];\n"
    }

    let ab = Get_ab()

    for (i in 0..=p) {
        for (a in ab) {
            if (dfa[i].node[a - 1].size > 0) {

                let label = String(Rune(a + 96))

                for (dst in dfa[i].node[a - 1]) {
                    sb += "    ${i} -> ${dst} [label=\"${label}\"];\n"
                }
            }
        }
    }

    sb += "}\n"

    let file = File(Path(filename), OpenMode.Write)
    file.write(sb.toArray())
    file.close()
    println("DFA 的 dot 文件已写入: " + filename)
}


main() {
    for (regexp in ["a|b", "aba", "(a|b)*", "bb(a|b)*a", "(aa)*", "a(b|c)*"]) {
        nfa.clear()
        dfa.clear()
        len = 0
        p = 0
        Dstates.clear()
        while (!s.isEmpty()) {
            s.pop()
        }
        Print_NFA(regexp)
        NFA_to_DFA()
        Print_DFA()

        // 将文件名中的非法字符替换为合法字符
        var safe_name = regexp.replace("|", "_or_")
                              .replace("*", "_star")
                              .replace("(", "")
                              .replace(")", "")
        
        Export_NFA_Dot("nfa_" + safe_name + ".dot")
        Export_DFA_Dot("dfa_" + safe_name + ".dot")

        println("----------------下一个测试用例---------------")
    }
}
