// DFA最小化 - 基于Hopcroft算法
// 包含：正则表达式->NFA->DFA->最小化DFA 的完整流程
package RegExp_NFA_DFA
import std.collection.*
import std.fs.*

struct FAnode {
    var node = Array(27, {_ => ArrayList<Int64>()})
}

// 泛型栈
struct Stack<T> {
    var elements = ArrayList<T>()

    func push(e: T) {
        elements.add(e)
    }

    func pop(): T {
        let lastIndex = elements.size - 1
        let value = elements[lastIndex]
        elements.remove(lastIndex..(lastIndex + 1))
        return value
    }

    func isEmpty(): Bool {
        return elements.size == 0
    }

    func top(): T {
        return elements[elements.size - 1]
    }
}

// DFA转换边结构
struct Transition {
    var src: Int64
    var dst: Int64
    var symbol: Int64

    init(s: Int64, d: Int64, sym: Int64) {
        src = s
        dst = d
        symbol = sym
    }
}

var nfa = ArrayList<FAnode>()
var len: Int64 = 0
var s: Stack<Int64> = Stack()
var dfa = ArrayList<FAnode>()
var p: Int64 = 0
var Dstates = ArrayList<HashSet<Int64>>()

// ============ RE转NFA部分 ============

func Add_symbol(regexp: String): String {
    var regexp2: String = ""
    var i: Int64 = 0
    while (i < regexp.size - 1) {
        let c1 = Rune(regexp[i])
        let c2 = Rune(regexp[i + 1])
        regexp2 += String(c1)
        if (c1 != r'(' && c2 != r')' && c1 != r'|' && c2 != r'|' && c2 != r'*') {
            regexp2 += '+'
        }
        i++
    }
    regexp2 += String(Rune(regexp[regexp.size - 1]))
    return regexp2
}

func Priority(ch: String): Int8 {
    if (ch == "*") { return 3 }
    else if (ch == "+") { return 2 }
    else if (ch == "|") { return 1 }
    else { return 0 }
}

func RegExp_to_Postfix(regexp2: String): String {
    var postfix: String = ""
    var s2: Stack<String> = Stack()
    for (i in regexp2) {
        let ch = String(Rune(i))
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
    while (!s2.isEmpty()) {
        postfix += s2.pop()
    }
    return postfix
}

func Get_are() {
    nfa.add(FAnode())
    nfa.add(FAnode())
}

func Do_ab(i: Int64) {
    Get_are()
    nfa[len].node[i].add(len + 1)
    s.push(len)
    s.push(len + 1)
    len += 2
}

func Do_star() {
    let b = s.pop()
    let a = s.pop()
    Get_are()
    nfa[b].node[0].add(a)
    nfa[len].node[0].add(a)
    nfa[len].node[0].add(len + 1)
    nfa[b].node[0].add(len + 1)
    s.push(len)
    s.push(len + 1)
    len += 2
}

func Do_or() {
    let a = s.pop()
    let b = s.pop()
    let c = s.pop()
    let d = s.pop()
    Get_are()
    nfa[a].node[0].add(len + 1)
    nfa[len].node[0].add(b)
    nfa[c].node[0].add(len + 1)
    nfa[len].node[0].add(d)
    s.push(len)
    s.push(len + 1)
    len += 2
}

func Do_add() {
    let d = s.pop()
    let b = s.pop()
    let a = s.pop()
    let c = s.pop()
    nfa[a].node[0].add(b)
    s.push(c)
    s.push(d)
}

func Postfix_to_NFA(postfix: String) {
    for (i in postfix) {
        let ch = String(Rune(i))
        if (ch <= "z" && ch >= "a") {
            Do_ab(Int64(i) - 97 + 1)
        } else if (ch == "*") {
            Do_star()
        } else if (ch == "+") {
            Do_add()
        } else if (ch == "|") {
            Do_or()
        }
    }
}

func Get_q0(): Int64 {
    for (k in 0..len) {
        var flag = true
        for (i in 0..len) {
            for (j in 0..=26) {
                if (nfa[i].node[j].contains(k)) {
                    flag = false
                    break
                }
            }
            if (!flag) { break }
        }
        if (flag) {
            return k
        }
    }
    return -1
}

func Get_F(): ArrayList<Int64> {
    var arr = ArrayList<Int64>()
    for (i in 0..len) {
        var flag = true
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

// ============ NFA转DFA部分 ============

func E_closure_single(t: Int64): HashSet<Int64> {
    var I = HashSet<Int64>()
    I.add(t)
    for (j in nfa[t].node[0]) {
        if (!I.contains(j)) {
            I.add(j)
            for (x in E_closure_single(j)) {
                I.add(x)
            }
        }
    }
    return I
}

func E_closure(I: HashSet<Int64>): HashSet<Int64> {
    var I2 = HashSet<Int64>()
    for (i in I) {
        for (x in E_closure_single(i)) {
            I2.add(x)
        }
    }
    return I2
}

func Edge_single(t: Int64, a: Int64): HashSet<Int64> {
    var I = HashSet<Int64>()
    for (j in nfa[t].node[a]) {
        I.add(j)
    }
    return I
}

func Edge(I: HashSet<Int64>, a: Int64): HashSet<Int64> {
    var J = HashSet<Int64>()
    for (t in I) {
        for (x in Edge_single(t, a)) {
            J.add(x)
        }
    }
    return J
}

func NFA_to_DFA() {
    var startState = HashSet<Int64>()
    startState.add(Get_q0())
    Dstates.add(E_closure(startState))
    dfa.add(FAnode())
    p = 0

    var j: Int64 = 0
    let ab = Get_ab()

    while (j <= p) {
        for (a in ab) {
            let e = E_closure(Edge(Dstates[j], a))
            if (e.size == 0) {
                continue
            }
            var idx: Int64 = -1
            for (k in 0..=p) {
                if (Dstates[k] == e) {
                    idx = k
                    break
                }
            }
            if (idx == -1) {
                p++
                Dstates.add(e)
                dfa.add(FAnode())
                idx = p
            }
            dfa[j].node[a - 1].add(idx)
        }
        j++
    }
}

func Get_DFA_F(): HashSet<Int64> {
    let NFA_F = Get_F()
    var DFA_F = HashSet<Int64>()
    for (i in NFA_F) {
        for (j in 0..=p) {
            if (Dstates[j].contains(i)) {
                DFA_F.add(j)
            }
        }
    }
    return DFA_F
}

func Print_DFA() {
    println("DFA:")
    print("Q = {")
    for (i in 0..=p) {
        if (i == p) { println("${i}}") }
        else { print("${i}, ") }
    }
    
    print("Σ = {")
    let ab = Get_ab()
    var count: Int64 = 0
    for (a in ab) {
        if (count == ab.size - 1) { println("${Rune(a + 96)}}") }
        else { print("${Rune(a + 96)}, ") }
        count++
    }
    
    print("δ = {")
    for (i in 0..=p) {
        for (a in ab) {
            if (dfa[i].node[a - 1].size > 0) {
                print("δ(${i},${Rune(a + 96)})={")
                for (dst in dfa[i].node[a - 1]) {
                    print("${dst}")
                }
                print("}, ")
            }
        }
    }
    println("}")
    
    println("q0 = 0")
    print("F = {")
    let F = Get_DFA_F()
    var f_count: Int64 = 0
    for (i in F) {
        f_count++
        if (f_count == F.size) { println("${i}}") }
        else { print("${i}, ") }
    }
}

func Export_DFA_Dot(filename: String) {
    var sb = "digraph DFA {\n    rankdir=LR;\n    node [shape=circle];\n"
    sb += "    start [shape=point];\n"
    sb += "    start -> 0 [label=\"start\"];\n"

    for (f in Get_DFA_F()) {
        sb += "    ${f} [shape=doublecircle];\n"
    }

    for (i in 0..=p) {
        for (a in Get_ab()) {
            if (dfa[i].node[a - 1].size > 0) {
                for (dst in dfa[i].node[a - 1]) {
                    sb += "    ${i} -> ${dst} [label=\"${Rune(a + 96)}\"];\n"
                }
            }
        }
    }

    sb += "}\n"
    File(Path(filename), OpenMode.Write).write(sb.toArray())
    println("DFA的dot文件已写入: " + filename)
}

// ============ DFA最小化部分 (Hopcroft算法) ============

func SetEquals(s1: HashSet<Int64>, s2: HashSet<Int64>): Bool {
    if (s1.size != s2.size) { return false }
    for (i in s1) {
        if (!s2.contains(i)) { return false }
    }
    return true
}

func GetFirst(s: HashSet<Int64>): Int64 {
    for (i in s) { return i }
    return -1
}

func Minimize_DFA(): (ArrayList<HashSet<Int64>>, ArrayList<Transition>, Int64, HashSet<Int64>) {
    let symbols = Get_ab()
    let accept_states = Get_DFA_F()
    
    var all_states = HashSet<Int64>()
    for (i in 0..=p) {
        all_states.add(i)
    }
    
    var non_accept = HashSet<Int64>()
    for (s in all_states) {
        if (!accept_states.contains(s)) {
            non_accept.add(s)
        }
    }
    
    var partition = ArrayList<HashSet<Int64>>()
    if (accept_states.size > 0) {
        partition.add(accept_states)
    }
    if (non_accept.size > 0) {
        partition.add(non_accept)
    }
    
    var worklist = ArrayList<HashSet<Int64>>()
    if (accept_states.size > 0) {
        worklist.add(accept_states)
    }
    
    // 构建转换表
    var state_trans = HashMap<Int64, HashMap<Int64, Int64>>()
    for (i in 0..=p) {
        var trans_map = HashMap<Int64, Int64>()
        for (sym in symbols) {
            trans_map[sym] = -1
        }
        state_trans[i] = trans_map
    }
    
    for (i in 0..=p) {
        for (a in symbols) {
            if (dfa[i].node[a - 1].size > 0) {
                for (dst in dfa[i].node[a - 1]) {
                    state_trans[i][a] = dst
                }
            }
        }
    }
    
    // Hopcroft算法主循环
    while (worklist.size > 0) {
        let splitter = worklist[worklist.size - 1]
        worklist.remove((worklist.size - 1)..(worklist.size))
        
        for (sym in symbols) {
            var affected = HashSet<Int64>()
            for (state in all_states) {
                let target = state_trans[state][sym]
                if (target != -1 && splitter.contains(target)) {
                    affected.add(state)
                }
            }
            
            var new_partition = ArrayList<HashSet<Int64>>()
            for (block in partition) {
                var intersect = HashSet<Int64>()
                var difference = HashSet<Int64>()
                
                for (s in block) {
                    if (affected.contains(s)) {
                        intersect.add(s)
                    } else {
                        difference.add(s)
                    }
                }
                
                if (intersect.size > 0 && difference.size > 0) {
                    new_partition.add(intersect)
                    new_partition.add(difference)
                    
                    var found = false
                    var idx = -1
                    for (i in 0..worklist.size) {
                        if (SetEquals(worklist[i], block)) {
                            found = true
                            idx = i
                            break
                        }
                    }
                    
                    if (found) {
                        worklist.remove(idx..(idx + 1))
                        worklist.add(intersect)
                        worklist.add(difference)
                    } else {
                        if (intersect.size <= difference.size) {
                            worklist.add(intersect)
                        } else {
                            worklist.add(difference)
                        }
                    }
                } else {
                    new_partition.add(block)
                }
            }
            partition = new_partition
        }
    }
    
    // 创建最小化DFA
    var state_map = HashMap<Int64, Int64>()
    for (i in 0..partition.size) {
        for (old_state in partition[i]) {
            state_map[old_state] = i
        }
    }
    
    var new_trans_set = HashSet<String>()
    var new_transitions = ArrayList<Transition>()
    
    for (i in 0..partition.size) {
        let repr = GetFirst(partition[i])
        for (sym in symbols) {
            let target = state_trans[repr][sym]
            if (target != -1) {
                let new_dst = state_map[target]
                let key = "${i}_${new_dst}_${sym}"
                if (!new_trans_set.contains(key)) {
                    new_transitions.add(Transition(i, new_dst, sym))
                    new_trans_set.add(key)
                }
            }
        }
    }
    
    let new_start = state_map[0]
    var new_accept = HashSet<Int64>()
    for (i in 0..partition.size) {
        for (old_accept in accept_states) {
            if (partition[i].contains(old_accept)) {
                new_accept.add(i)
                break
            }
        }
    }
    
    return (partition, new_transitions, new_start, new_accept)
}

func Print_Minimized_DFA(partition: ArrayList<HashSet<Int64>>, 
                          transitions: ArrayList<Transition>,
                          start_state: Int64,
                          accept_states: HashSet<Int64>) {
    println("最小化DFA:")
    
    print("Q = {")
    for (i in 0..partition.size) {
        if (i == partition.size - 1) { println("S${i}}") }
        else { print("S${i}, ") }
    }
    
    print("状态映射: ")
    for (i in 0..partition.size) {
        print("S${i}={")
        var first = true
        for (old_state in partition[i]) {
            if (!first) { print(",") }
            print("${old_state}")
            first = false
        }
        print("} ")
    }
    println()
    
    print("Σ = {")
    let symbols = Get_ab()
    var count: Int64 = 0
    for (sym in symbols) {
        if (count == symbols.size - 1) { println("${Rune(sym + 96)}}") }
        else { print("${Rune(sym + 96)}, ") }
        count++
    }
    
    print("δ = {")
    for (t in transitions) {
        print("δ(S${t.src},${Rune(t.symbol + 96)})=S${t.dst}, ")
    }
    println("}")
    
    println("q0 = S${start_state}")
    
    print("F = {")
    var f_count: Int64 = 0
    for (f in accept_states) {
        f_count++
        if (f_count == accept_states.size) { println("S${f}}") }
        else { print("S${f}, ") }
    }
}

func Export_Minimized_DFA_Dot(filename: String,
                               num_states: Int64,
                               transitions: ArrayList<Transition>,
                               start_state: Int64,
                               accept_states: HashSet<Int64>) {
    var sb = "digraph MinimizedDFA {\n    rankdir=LR;\n    node [shape=circle];\n"
    sb += "    start [shape=point];\n"
    sb += "    start -> S${start_state} [label=\"start\"];\n"
    
    for (f in accept_states) {
        sb += "    S${f} [shape=doublecircle];\n"
    }
    
    for (t in transitions) {
        sb += "    S${t.src} -> S${t.dst} [label=\"${Rune(t.symbol + 96)}\"];\n"
    }
    
    sb += "}\n"
    File(Path(filename), OpenMode.Write).write(sb.toArray())
    println("最小化DFA的dot文件已写入: " + filename)
}

// ============ 主程序 ============

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
        
        println("正规式：" + regexp)
        let regexp2 = Add_symbol(regexp)
        let postfix = RegExp_to_Postfix(regexp2)
        Postfix_to_NFA(postfix)
        
        NFA_to_DFA()
        Print_DFA()
        
        println("\n开始DFA最小化...")
        let (partition, min_trans, min_start, min_accept) = Minimize_DFA()
        Print_Minimized_DFA(partition, min_trans, min_start, min_accept)
        
        let safe_name = regexp.replace("|", "_or_")
                              .replace("*", "_star")
                              .replace("(", "")
                              .replace(")", "")
        
        Export_DFA_Dot("dfa_" + safe_name + ".dot")
        Export_Minimized_DFA_Dot("min_dfa_" + safe_name + ".dot", 
                                 partition.size, min_trans, min_start, min_accept)
        
        println("=================下一个测试用例=================\n")
    }
}

