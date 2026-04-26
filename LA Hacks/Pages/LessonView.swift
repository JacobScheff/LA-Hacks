//
//  LessonView.swift
//  LA Hacks
//
//  Star Hop! conversational tutoring — Nova chats with the student.
//  Redesigned as a chat thread matching project/lesson.jsx.
//

import SwiftUI

var streamedResponse: String = ""
var lastAnswerCorrect: Bool? = nil

// MARK: - Problem types

enum ProblemKind {
    case multipleChoice
    case input
    case pizza
}

struct LessonProblem: Identifiable {
    let id = UUID()
    let kind: ProblemKind
    let prompt: String
    let hint: String
    let answer: String
    let choices: [String]
    let slices: Int
    let target: Int

    static func mc(_ prompt: String, choices: [String], answer: String, hint: String) -> LessonProblem {
        LessonProblem(kind: .multipleChoice, prompt: prompt, hint: hint, answer: answer, choices: choices, slices: 0, target: 0)
    }
    static func input(_ prompt: String, answer: String, hint: String) -> LessonProblem {
        LessonProblem(kind: .input, prompt: prompt, hint: hint, answer: answer, choices: [], slices: 0, target: 0)
    }
    static func pizza(_ prompt: String, slices: Int, target: Int, hint: String) -> LessonProblem {
        LessonProblem(kind: .pizza, prompt: prompt, hint: hint, answer: "correct", choices: [], slices: slices, target: target)
    }
}

struct LessonContent {
    let intro: String
    let exampleQuestion: String
    let exampleAnswer: String
    let exampleViz: String
    let problems: [LessonProblem]
}

// MARK: - Lesson bank (static fallbacks for hardcoded stars)

func lessonFor(node: StarNode) -> LessonContent {
    switch node.id {
    case "add":
        return LessonContent(
            intro: "Adding means putting groups together to make something bigger. Every adventure starts with one small step! 🌟",
            exampleQuestion: "If you have 3 star-rocks and find 4 more, how many do you have?",
            exampleAnswer: "7",
            exampleViz: "⭐⭐⭐ + ⭐⭐⭐⭐ = ?",
            problems: [
                .mc("A space dog has 5 bones and digs up 3 more. How many bones total?", choices: ["6","7","8","9"], answer: "8", hint: "Count up from 5: 6, 7, 8."),
                .input("12 + 7 = ?", answer: "19", hint: "Start at 12 and hop forward 7 times."),
                .mc("Which one equals 14?", choices: ["9 + 4","7 + 7","5 + 10","8 + 8"], answer: "7 + 7", hint: "Doubles can help! What is 7 doubled?"),
                .input("25 + 36 = ?", answer: "61", hint: "Add the tens (20+30=50), then the ones (5+6=11). 50+11=?"),
            ]
        )
    case "mul":
        return LessonContent(
            intro: "Times tables are super-speedy adding! 3 × 4 means '3 groups of 4'. ⚡",
            exampleQuestion: "3 × 4 = ? (think: 4 + 4 + 4)",
            exampleAnswer: "12",
            exampleViz: "⭐⭐⭐⭐  ⭐⭐⭐⭐  ⭐⭐⭐⭐",
            problems: [
                .mc("6 × 7 = ?", choices: ["36","42","48","49"], answer: "42", hint: "6 × 7 is the same as 7 × 6. Try counting by 6s."),
                .input("8 × 9 = ?", answer: "72", hint: "9s trick: tens digit is one less than 8, so 7_. Digits add to 9 → 72!"),
                .mc("5 spiders, each with 8 legs. How many legs total?", choices: ["35","40","45","48"], answer: "40", hint: "Count by 5s: 8, 16, 24, 32, 40."),
                .input("12 × 5 = ?", answer: "60", hint: "Half of 12 × 10. What is 12 × 10?"),
            ]
        )
    case "half":
        return LessonContent(
            intro: "A half means TWO equal pieces. A quarter means FOUR equal pieces. 🍕",
            exampleQuestion: "Which fraction means 1 out of 2 equal parts?",
            exampleAnswer: "½",
            exampleViz: "🍕",
            problems: [
                .pizza("Tap to show ½ of the pizza.", slices: 2, target: 1, hint: "Half means 1 of 2 equal pieces."),
                .mc("Which is bigger, ½ or ¼?", choices: ["½","¼","They are equal"], answer: "½", hint: "More slices cut = smaller each slice!"),
                .pizza("Tap to show ¾ of the pizza.", slices: 4, target: 3, hint: "¾ = 3 out of 4 equal pieces."),
            ]
        )
    case "addfrac":
        return LessonContent(
            intro: "When fractions have the SAME bottom number, just add the tops! The bottom stays. 🧮",
            exampleQuestion: "1/4 + 2/4 = ?",
            exampleAnswer: "3/4 (add tops: 1+2=3, keep bottom: 4)",
            exampleViz: "🍕 1/4 + 🍕🍕 2/4",
            problems: [
                .mc("2/5 + 1/5 = ?", choices: ["3/10","3/5","2/5","1/5"], answer: "3/5", hint: "Tops add: 2+1=3. Bottom stays 5."),
                .mc("3/8 + 4/8 = ?", choices: ["7/16","7/8","12/8","1/8"], answer: "7/8", hint: "Add the tops (3+4), keep the bottom (8)."),
            ]
        )
    case "tri":
        return LessonContent(
            intro: "Triangles have 3 sides and 3 corners. They're everywhere — pizza slices, yield signs! 🔺",
            exampleQuestion: "How many sides on a triangle?",
            exampleAnswer: "3",
            exampleViz: "🔺",
            problems: [
                .mc("How many corners (vertices) on a triangle?", choices: ["2","3","4","5"], answer: "3", hint: "Same as the number of sides!"),
                .mc("Which shape is NOT a triangle?", choices: ["A yield sign shape","A square","A slice of pizza","A mountain outline"], answer: "A square", hint: "A square has 4 sides."),
            ]
        )
    case "area":
        return LessonContent(
            intro: "Area is how much flat SPACE is inside a shape. Count the squares inside! 📐",
            exampleQuestion: "A 3×4 rectangle — how many squares fit inside?",
            exampleAnswer: "12 (3 × 4 = 12)",
            exampleViz: "3 rows × 4 cols",
            problems: [
                .mc("A 5 × 4 rug. What is the area in square units?", choices: ["9","18","20","24"], answer: "20", hint: "Multiply length × width."),
                .input("A square with side length 6. Area = ?", answer: "36", hint: "6 × 6."),
            ]
        )
    case "main":
        return LessonContent(
            intro: "The MAIN IDEA is what a whole story is mostly about. The big picture! 🖼️",
            exampleQuestion: "A story about a lost puppy who finds a new family. What's the main idea?",
            exampleAnswer: "A lost puppy finds a new family",
            exampleViz: "🐶❤️🏠",
            problems: [
                .mc("Rosa learns to ride a bike after many tries. Main idea?",
                    choices: ["Rosa likes ice cream","Rosa learns to ride a bike with practice","Bikes have two wheels"],
                    answer: "Rosa learns to ride a bike with practice",
                    hint: "What is the WHOLE story really about?"),
                .mc("A passage explains how bees make honey. The main idea is about…",
                    choices: ["Flowers being pretty","How bees make honey","Bears liking honey"],
                    answer: "How bees make honey", hint: "It's right there in the description!"),
            ]
        )
    case "habitat":
        return LessonContent(
            intro: "A HABITAT is where a plant or animal lives and finds everything it needs. Its home! 🌿",
            exampleQuestion: "Where does a polar bear live?",
            exampleAnswer: "The Arctic — cold, icy, perfect for polar bears!",
            exampleViz: "🐻‍❄️❄️",
            problems: [
                .mc("A cactus lives where?", choices: ["Ocean","Desert","Forest","Pond"], answer: "Desert", hint: "Cacti love hot, dry, sandy places!"),
                .mc("Which animal lives in a coral reef?", choices: ["Wolf","Camel","Clownfish","Penguin"], answer: "Clownfish", hint: "Think Finding Nemo!"),
            ]
        )
    case "count":
        return LessonContent(
            intro: "Counting is how we know HOW MANY there are! Start at 1 and keep going — or skip-count by 2s, 5s, or 10s for turbo speed! 🚀",
            exampleQuestion: "What number comes after 17?",
            exampleAnswer: "18",
            exampleViz: "1 2 3 … 17 ➡️ ?",
            problems: [
                .mc("Count by 2s: 2, 4, 6, 8, __?", choices: ["9","10","11","12"], answer: "10", hint: "Each jump adds 2 more."),
                .input("Count by 5s: 5, 10, 15, 20, __?", answer: "25", hint: "Hop by 5 each time."),
                .mc("Count by 10s: 10, 20, 30, __?", choices: ["35","40","50","45"], answer: "40", hint: "Each jump is +10."),
                .input("What is the total? ⭐⭐⭐⭐⭐ and ⭐⭐⭐⭐⭐⭐⭐", answer: "12", hint: "Count all the stars one by one."),
            ]
        )
    case "place":
        return LessonContent(
            intro: "Place value is like a ZIP code for numbers! The ONES place, the TENS place, the HUNDREDS place — each spot means something different. 🏠",
            exampleQuestion: "In the number 345, what digit is in the tens place?",
            exampleAnswer: "4",
            exampleViz: "3️⃣ hundreds · 4️⃣ tens · 5️⃣ ones",
            problems: [
                .mc("What is the value of the digit 7 in 274?", choices: ["7","70","700","17"], answer: "70", hint: "The 7 is in the tens place → 7 × 10 = 70."),
                .input("How many tens are in 530?", answer: "53", hint: "530 ÷ 10 = ?"),
                .mc("Which number has a 6 in the hundreds place?", choices: ["136","614","316","163"], answer: "614", hint: "Hundreds is the leftmost digit of a 3-digit number."),
                .mc("What is 300 + 40 + 9?", choices: ["349","394","439","934"], answer: "349", hint: "Write each place value out: 3 hundreds, 4 tens, 9 ones."),
            ]
        )
    case "sub":
        return LessonContent(
            intro: "Subtracting means taking away — it's counting backwards! If you have 9 cookies and eat 3, how many are left? Count back! 🍪",
            exampleQuestion: "15 − 8 = ?",
            exampleAnswer: "7",
            exampleViz: "15 ⬅️ 8 steps = ?",
            problems: [
                .mc("A bag had 13 marbles. You lost 5. How many left?", choices: ["6","7","8","9"], answer: "8", hint: "Count back from 13: 12, 11, 10, 9, 8."),
                .input("47 − 19 = ?", answer: "28", hint: "Try 47 − 20 = 27, then add 1 back: 28."),
                .mc("Which subtraction fact equals 6?", choices: ["13−6","15−8","11−5","12−7"], answer: "12−7", hint: "Check each: 12−7=5… wait, try them all!"),
                .input("100 − 37 = ?", answer: "63", hint: "100 − 37: think of it as 100 − 40 + 3 = 63."),
            ]
        )
    case "div":
        return LessonContent(
            intro: "Division is fair sharing! If 12 cookies are split among 3 friends, everyone gets the same amount. ÷ is the sharing symbol! 🍪➗",
            exampleQuestion: "12 ÷ 3 = ? (share 12 cookies between 3 friends)",
            exampleAnswer: "4 each",
            exampleViz: "🍪🍪🍪🍪 | 🍪🍪🍪🍪 | 🍪🍪🍪🍪",
            problems: [
                .mc("24 ÷ 6 = ?", choices: ["3","4","5","6"], answer: "4", hint: "6 × ? = 24. Think times tables in reverse!"),
                .input("35 ÷ 7 = ?", answer: "5", hint: "7 × 5 = 35 — use your 7s times table."),
                .mc("You have 30 stickers to share equally in 5 bags. How many in each?", choices: ["4","5","6","7"], answer: "6", hint: "30 ÷ 5 = ? Count by 5s to 30."),
                .input("81 ÷ 9 = ?", answer: "9", hint: "9 × 9 = 81!"),
            ]
        )
    case "odd":
        return LessonContent(
            intro: "EVEN numbers can be split into two equal groups — no leftovers! ODD numbers always have one left over. 2, 4, 6, 8 are even. 1, 3, 5, 7 are odd! 👯",
            exampleQuestion: "Is 14 odd or even?",
            exampleAnswer: "Even — it ends in 4, and 14 ÷ 2 = 7 exactly.",
            exampleViz: "14 = 7 + 7 ✅",
            problems: [
                .mc("Which of these numbers is ODD?", choices: ["12","24","37","50"], answer: "37", hint: "Odd numbers end in 1, 3, 5, 7, or 9."),
                .mc("Which of these is EVEN?", choices: ["17","35","82","99"], answer: "82", hint: "Even numbers end in 0, 2, 4, 6, or 8."),
                .mc("Odd + Odd = ?", choices: ["Always even","Always odd","Sometimes even"], answer: "Always even", hint: "Try 3+5=8, 7+1=8 — always even!"),
                .input("How many even numbers are between 1 and 10?", answer: "5", hint: "Count: 2, 4, 6, 8, 10 — that's 5."),
            ]
        )
    case "frac":
        return LessonContent(
            intro: "A fraction has TWO parts: the TOP (numerator) = how many pieces you have, and the BOTTOM (denominator) = how many pieces total. 3/5 means 3 out of 5! 📖",
            exampleQuestion: "In the fraction 3/8, what is the denominator?",
            exampleAnswer: "8 — the total number of equal parts.",
            exampleViz: "3 ← numerator\n—\n8 ← denominator",
            problems: [
                .mc("In 5/6, what is the numerator?", choices: ["6","5","1","56"], answer: "5", hint: "Numerator is on TOP."),
                .mc("A pizza is cut into 8 slices. You eat 3. What fraction did you eat?", choices: ["8/3","3/5","3/8","5/8"], answer: "3/8", hint: "You ate 3 of the 8 equal slices."),
                .input("Write the fraction: 2 out of 7 equal parts. (use format like 2/7)", answer: "2/7", hint: "Pieces you have → top. Total pieces → bottom."),
                .mc("Which fraction is closest to 1 whole?", choices: ["1/8","2/3","7/8","3/8"], answer: "7/8", hint: "The bigger the numerator is compared to the denominator, the closer to 1."),
            ]
        )
    case "equiv":
        return LessonContent(
            intro: "Equal fractions look different but mean the SAME amount! 1/2 = 2/4 = 4/8. Multiply or divide BOTH top and bottom by the same number. 🟰",
            exampleQuestion: "Is 2/4 equal to 1/2?",
            exampleAnswer: "YES! 2÷2 = 1 and 4÷2 = 2 → same value.",
            exampleViz: "½ = 2/4 = 4/8",
            problems: [
                .mc("Which fraction equals 1/3?", choices: ["2/5","2/6","3/6","4/9"], answer: "2/6", hint: "1×2=2 and 3×2=6 → 2/6."),
                .mc("Fill in the blank: 3/4 = ?/8", choices: ["5","6","7","4"], answer: "6", hint: "Bottom went from 4 to 8 (×2), so top: 3×2=6."),
                .input("3/9 simplified = ?/3 (type the missing numerator)", answer: "1", hint: "Divide both by 3: 3÷3=1, 9÷3=3."),
                .mc("Which pair are equal fractions?", choices: ["1/2 and 2/5","3/4 and 6/8","2/3 and 3/4","1/4 and 1/8"], answer: "3/4 and 6/8", hint: "3×2=6 and 4×2=8 ✓"),
            ]
        )
    case "compare":
        return LessonContent(
            intro: "To compare fractions with the SAME bottom: bigger top wins! 3/5 > 2/5. Different bottoms? Find a common denominator first! ⚖️",
            exampleQuestion: "Which is bigger: 3/4 or 2/4?",
            exampleAnswer: "3/4 — same bottom, bigger top wins!",
            exampleViz: "3/4 🆚 2/4 → 3 > 2 ✓",
            problems: [
                .mc("Which is bigger: 5/8 or 3/8?", choices: ["5/8","3/8","They're equal"], answer: "5/8", hint: "Same bottom (8) → compare tops: 5 > 3."),
                .mc("Which is smaller: 1/3 or 1/4?", choices: ["1/3","1/4","They're equal"], answer: "1/4", hint: "Bigger bottom = smaller slices. 4 slices vs 3 slices."),
                .mc("Put in order smallest to largest: 2/5, 4/5, 1/5", choices: ["1/5, 2/5, 4/5","2/5, 1/5, 4/5","4/5, 2/5, 1/5"], answer: "1/5, 2/5, 4/5", hint: "Same bottom — just sort by top number: 1, 2, 4."),
                .mc("Which is closer to 1 whole: 3/4 or 2/3?", choices: ["3/4","2/3","Same distance"], answer: "3/4", hint: "3/4 = 0.75, 2/3 ≈ 0.67 — which is higher?"),
            ]
        )
    case "mixed":
        return LessonContent(
            intro: "Mixed numbers are a whole number PLUS a fraction! 2¾ means 2 whole pies and ¾ of another. They live between two whole numbers on the number line. 🥧",
            exampleQuestion: "What mixed number is shown by 1 whole pizza plus 2 slices of a pizza cut into 4?",
            exampleAnswer: "1 and 2/4 (or 1½)",
            exampleViz: "🍕 + 🍕🍕 (of 4) = 1 2/4",
            problems: [
                .mc("What mixed number equals 7/4?", choices: ["1 and 3/4","2 and 1/4","1 and 1/4","2 and 3/4"], answer: "1 and 3/4", hint: "7÷4 = 1 remainder 3 → 1 and 3/4."),
                .mc("Convert 2 and 1/3 to an improper fraction.", choices: ["5/3","7/3","6/3","3/3"], answer: "7/3", hint: "2×3=6, plus the 1 on top: 6+1=7 → 7/3."),
                .input("3 and 2/5 = ?/5 (improper fraction — enter the numerator)", answer: "17", hint: "3×5=15, then 15+2=17 → 17/5."),
                .mc("Which is largest?", choices: ["1 and 3/4","2 and 1/8","1 and 7/8","2 and 1/2"], answer: "2 and 1/2", hint: "Both 2-wholes beat the 1-wholes. Compare 1/8 vs 1/2: 1/2 is bigger."),
            ]
        )
    case "simplify":
        return LessonContent(
            intro: "Simplifying means finding the SMALLEST equal fraction. Divide both top and bottom by the same number until you can't anymore — that's the simplest form! ✂️",
            exampleQuestion: "Simplify 4/8.",
            exampleAnswer: "1/2 (divide both by 4)",
            exampleViz: "4/8 ÷ 4 → 1/2 ✂️",
            problems: [
                .mc("Simplify 6/9.", choices: ["3/4","2/3","1/3","3/9"], answer: "2/3", hint: "GCF of 6 and 9 is 3. 6÷3=2, 9÷3=3."),
                .mc("Simplify 10/15.", choices: ["5/8","2/3","1/2","3/5"], answer: "2/3", hint: "Divide both by 5: 10÷5=2, 15÷5=3."),
                .input("Simplify 8/12 to its simplest form. (type like 2/3)", answer: "2/3", hint: "GCF is 4: 8÷4=2, 12÷4=3."),
                .mc("Which fraction is ALREADY fully simplified?", choices: ["4/6","3/9","5/7","2/8"], answer: "5/7", hint: "5 and 7 share no common factors besides 1."),
            ]
        )
    case "word":
        return LessonContent(
            intro: "Fraction word problems are puzzles! Read carefully, find the fraction, decide: add? subtract? compare? Then solve step by step. 🧩",
            exampleQuestion: "A recipe needs 3/4 cup of sugar. You only have 1/4 cup. How much more do you need?",
            exampleAnswer: "2/4 cup (or 1/2 cup)",
            exampleViz: "3/4 − 1/4 = 2/4 = 1/2",
            problems: [
                .mc("Maria ran 2/5 of a mile. Leo ran 4/5 of a mile. How much MORE did Leo run?", choices: ["1/5","2/5","3/5","6/5"], answer: "2/5", hint: "Subtract: 4/5 − 2/5 = 2/5."),
                .mc("A pie is cut into 8 slices. The family ate 5 slices. What fraction is LEFT?", choices: ["5/8","3/8","2/8","4/8"], answer: "3/8", hint: "8 total − 5 eaten = 3 left → 3/8."),
                .input("Tom drank 1/3 of a bottle. Sam drank 1/3 too. What fraction was drunk total? (type like 2/3)", answer: "2/3", hint: "1/3 + 1/3 = 2/3. Same bottom — add tops!"),
                .mc("A rope is 3/4 meter long. Another is 1/2 meter. Together, how long are they?", choices: ["4/6 m","5/4 m","4/4 m","3/8 m"], answer: "5/4 m", hint: "1/2 = 2/4. Then 3/4 + 2/4 = 5/4."),
            ]
        )
    case "sq":
        return LessonContent(
            intro: "Squares have 4 EQUAL sides and 4 right-angle corners. A rectangle has 4 right angles too — but only opposite sides are equal. Every square IS a rectangle! 🟦",
            exampleQuestion: "How many sides does a square have?",
            exampleAnswer: "4 — all the same length!",
            exampleViz: "🟦 4 equal sides · 4 right angles",
            problems: [
                .mc("A square has sides of 5 cm. What is its perimeter?", choices: ["15 cm","20 cm","25 cm","10 cm"], answer: "20 cm", hint: "Perimeter = 4 × side = 4 × 5."),
                .mc("A rectangle is 6 m long and 3 m wide. Perimeter?", choices: ["9 m","18 m","12 m","15 m"], answer: "18 m", hint: "P = 2 × (length + width) = 2 × (6+3)."),
                .mc("Which shape is ALWAYS a square?", choices: ["Rectangle with equal sides","Any 4-sided shape","Rectangle with unequal sides","Parallelogram"], answer: "Rectangle with equal sides", hint: "A square = rectangle with all sides equal."),
                .input("A square room has a perimeter of 24 m. How long is each side?", answer: "6", hint: "24 ÷ 4 sides = ?"),
            ]
        )
    case "circ":
        return LessonContent(
            intro: "A circle is perfectly round! The RADIUS goes from center to edge. The DIAMETER crosses the whole middle = 2 × radius. No corners, no sides! ⭕",
            exampleQuestion: "A circle has a radius of 5 cm. What is the diameter?",
            exampleAnswer: "10 cm — diameter = 2 × radius.",
            exampleViz: "⭕ radius=5 → diameter=10",
            problems: [
                .mc("A circle has a diameter of 14 m. What is the radius?", choices: ["14 m","7 m","28 m","4 m"], answer: "7 m", hint: "Radius = diameter ÷ 2 = 14 ÷ 2."),
                .mc("Which of these is NOT a circle?", choices: ["A coin","A wheel","A pizza","A slice of pizza"], answer: "A slice of pizza", hint: "A slice is a wedge / sector shape, not a full circle."),
                .mc("The diameter of a round pond is 20 m. What is the radius?", choices: ["5 m","10 m","20 m","40 m"], answer: "10 m", hint: "Half of 20 is 10."),
                .input("A circle's radius is 3 cm. What is the diameter in cm?", answer: "6", hint: "Diameter = 2 × radius = 2 × 3."),
            ]
        )
    case "poly":
        return LessonContent(
            intro: "A POLYGON is any closed flat shape made of straight sides. 3 sides = triangle. 4 sides = quadrilateral. 5 = pentagon. 6 = hexagon. 8 = octagon! 🔶",
            exampleQuestion: "A stop sign has 8 sides. What kind of polygon is it?",
            exampleAnswer: "An octagon!",
            exampleViz: "3→△  4→□  5→⬠  6→⬡  8→🛑",
            problems: [
                .mc("How many sides does a pentagon have?", choices: ["4","5","6","7"], answer: "5", hint: "Penta = 5 in Greek."),
                .mc("A honeycomb cell has 6 sides. What is it?", choices: ["Pentagon","Hexagon","Octagon","Heptagon"], answer: "Hexagon", hint: "Hex = 6 in Greek."),
                .mc("Which of these is NOT a polygon?", choices: ["Triangle","Circle","Rectangle","Hexagon"], answer: "Circle", hint: "Circles have curved sides, not straight."),
                .input("How many sides does an octagon have?", answer: "8", hint: "Octo = 8 (like an octopus has 8 arms!)."),
            ]
        )
    case "sym":
        return LessonContent(
            intro: "A shape has SYMMETRY if you can fold it so both halves match perfectly. The fold line is the LINE OF SYMMETRY. A square has 4! 🦋",
            exampleQuestion: "Does the letter 'A' have a line of symmetry?",
            exampleAnswer: "YES — fold it down the middle and both sides match!",
            exampleViz: "A → left | right match ✓",
            problems: [
                .mc("How many lines of symmetry does a circle have?", choices: ["0","1","4","Infinite"], answer: "Infinite", hint: "Any line through the center splits a circle in half!"),
                .mc("Which letter has NO line of symmetry?", choices: ["A","M","Z","T"], answer: "Z", hint: "Try folding each letter mentally — Z's halves don't match."),
                .mc("A square has how many lines of symmetry?", choices: ["1","2","4","8"], answer: "4", hint: "Two through opposite corners, two through midpoints of sides."),
                .mc("Which shape has exactly 1 line of symmetry?", choices: ["Square","Circle","Isosceles triangle","Equilateral triangle"], answer: "Isosceles triangle", hint: "An isosceles triangle has 2 equal sides, and one fold line down the middle."),
            ]
        )
    case "angle":
        return LessonContent(
            intro: "An ANGLE is the amount of turn between two lines meeting at a point. A RIGHT angle = 90° (corner of a square!). ACUTE < 90°. OBTUSE > 90°. 📐",
            exampleQuestion: "Is the corner of a book acute, right, or obtuse?",
            exampleAnswer: "Right angle — exactly 90°!",
            exampleViz: "Acute < 90° · Right = 90° · Obtuse > 90°",
            problems: [
                .mc("An angle of 45° is…", choices: ["Acute","Right","Obtuse","Straight"], answer: "Acute", hint: "45° < 90° → acute!"),
                .mc("An angle of 120° is…", choices: ["Acute","Right","Obtuse","Reflex"], answer: "Obtuse", hint: "120° > 90° but < 180° → obtuse."),
                .mc("A straight line forms an angle of…", choices: ["45°","90°","180°","360°"], answer: "180°", hint: "A straight line is a completely flat angle = 180°."),
                .input("A triangle's angles add up to how many degrees?", answer: "180", hint: "All three angles of any triangle always sum to 180°."),
            ]
        )
    case "vol":
        return LessonContent(
            intro: "VOLUME is how much 3D space is inside a solid shape. Count the unit cubes, or use the formula: V = length × width × height. 🧊",
            exampleQuestion: "A box is 3 cm long, 2 cm wide, 4 cm tall. What is the volume?",
            exampleAnswer: "24 cm³ (3 × 2 × 4 = 24)",
            exampleViz: "🧊 3 × 2 × 4 = 24 cubes",
            problems: [
                .mc("A box is 5 × 3 × 2. Volume?", choices: ["10","15","30","25"], answer: "30", hint: "5 × 3 × 2 = 30."),
                .input("A cube has side length 4 cm. Volume = ?", answer: "64", hint: "4 × 4 × 4 = 64 cm³."),
                .mc("Which has the bigger volume? Box A: 2×3×4 or Box B: 1×5×5?", choices: ["Box A","Box B","Same"], answer: "Box A", hint: "A: 24 cubic units; B: 25 cubic units — actually B is larger!"),
                .mc("Volume is measured in…", choices: ["Square units","Cubic units","Linear units","Flat units"], answer: "Cubic units", hint: "3D space → 3 dimensions → cubic!"),
            ]
        )
    case "clock":
        return LessonContent(
            intro: "The SHORT hand points to the HOUR. The LONG hand points to the MINUTES. When the long hand is on 12, it's exactly on the hour! 🕒",
            exampleQuestion: "The short hand is on 3 and the long hand is on 12. What time is it?",
            exampleAnswer: "3:00",
            exampleViz: "🕒 short→3, long→12 = 3:00",
            problems: [
                .mc("The short hand is on 7 and the long hand is on 12. Time?", choices: ["7:00","12:07","7:12","12:00"], answer: "7:00", hint: "Long hand on 12 = exactly on the hour."),
                .mc("The short hand is halfway between 4 and 5. The long hand is on 6. Time?", choices: ["4:06","4:30","5:30","6:04"], answer: "4:30", hint: "Long hand on 6 = 30 minutes."),
                .mc("Which shows 2:15?", choices: ["Short on 2, long on 3","Short on 3, long on 2","Short on 2, long on 12","Short on 2, long on 6"], answer: "Short on 2, long on 3", hint: "Long hand on 3 = 15 minutes past."),
                .mc("On a digital clock, 6:45 means…", choices: ["6 hours 45 minutes","45 hours 6 minutes","Quarter to 7","Both A and C"], answer: "Both A and C", hint: "6:45 = 6 hours and 45 minutes = 15 minutes before 7."),
            ]
        )
    case "min":
        return LessonContent(
            intro: "There are 60 minutes in 1 hour. Each number on the clock stands for 5 minutes. Long hand on 1 = 5 min. On 2 = 10 min. On 6 = 30 min! ⏱️",
            exampleQuestion: "The long hand points to 4. How many minutes past the hour?",
            exampleAnswer: "20 minutes (4 × 5 = 20)",
            exampleViz: "4 × 5 = 20 minutes",
            problems: [
                .mc("Long hand on 9. How many minutes?", choices: ["9","40","45","54"], answer: "45", hint: "9 × 5 = 45 minutes."),
                .mc("How many minutes in 2 hours?", choices: ["60","90","100","120"], answer: "120", hint: "2 × 60 = 120."),
                .input("Long hand on 7. How many minutes past the hour?", answer: "35", hint: "7 × 5 = 35."),
                .mc("It is 3:25 now. What time will it be in 20 minutes?", choices: ["3:45","4:05","3:55","4:00"], answer: "3:45", hint: "25 + 20 = 45, still within the same hour."),
            ]
        )
    case "cal":
        return LessonContent(
            intro: "A calendar shows days, weeks, and months. 7 days = 1 week. 12 months = 1 year. Some months have 30 days, some 31 — except February (28 or 29)! 📅",
            exampleQuestion: "How many days are in a week?",
            exampleAnswer: "7",
            exampleViz: "Mon Tue Wed Thu Fri Sat Sun = 7",
            problems: [
                .mc("How many months are in a year?", choices: ["10","11","12","13"], answer: "12", hint: "Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec."),
                .mc("If today is Tuesday, what day is it in 3 days?", choices: ["Thursday","Friday","Wednesday","Saturday"], answer: "Friday", hint: "Tue → Wed → Thu → Fri."),
                .mc("Which month comes after September?", choices: ["August","November","October","December"], answer: "October", hint: "…Aug, Sep, Oct, Nov, Dec…"),
                .input("How many weeks are in 28 days?", answer: "4", hint: "28 ÷ 7 = ?"),
            ]
        )
    case "elapsed":
        return LessonContent(
            intro: "ELAPSED time is how long something TAKES. Count forward from the start time to the end time on a number line or with a clock! ⌛",
            exampleQuestion: "A movie starts at 2:00 and ends at 4:30. How long is it?",
            exampleAnswer: "2 hours 30 minutes",
            exampleViz: "2:00 ➡️ 4:00 (2 hr) ➡️ 4:30 (+30 min)",
            problems: [
                .mc("School starts at 8:00 AM and ends at 3:00 PM. How many hours?", choices: ["5","6","7","8"], answer: "7", hint: "Count from 8 to 3: 8→9→10→11→12→1→2→3 = 7 hours."),
                .mc("Practice starts at 4:15 and ends at 5:45. How long?", choices: ["1 hr 15 min","1 hr 30 min","1 hr 45 min","2 hr"], answer: "1 hr 30 min", hint: "4:15 → 5:15 = 1 hour, then +30 min."),
                .input("A cake bakes from 6:20 to 7:05. How many minutes does it take?", answer: "45", hint: "6:20 → 6:60 (7:00) = 40 min, then +5 = 45 min."),
                .mc("Lena left at 9:30 AM. She arrived at 11:00 AM. How long was the trip?", choices: ["30 min","1 hr","1 hr 30 min","2 hr"], answer: "1 hr 30 min", hint: "9:30 → 10:30 = 1 hour, then 10:30 → 11:00 = 30 min."),
            ]
        )
    case "rasalas":
        return LessonContent(
            intro: "AM = hours from midnight (12:00 AM) to noon (12:00 PM). PM = noon to midnight. Breakfast is AM. Dinner is PM! 🌗",
            exampleQuestion: "Is 7 in the morning AM or PM?",
            exampleAnswer: "AM — before noon!",
            exampleViz: "🌙 midnight → ☀️ noon → 🌙 midnight\n  ← AM →        ← PM →",
            problems: [
                .mc("School starts at 8 in the morning. Is that 8 AM or 8 PM?", choices: ["8 AM","8 PM"], answer: "8 AM", hint: "Morning = AM."),
                .mc("Bedtime is 9 at night. That is…", choices: ["9 AM","9 PM"], answer: "9 PM", hint: "Night = PM."),
                .mc("Noon is…", choices: ["12 AM","12 PM","6 AM","6 PM"], answer: "12 PM", hint: "Noon = midday = 12 PM. Midnight = 12 AM."),
                .mc("What time is 3 hours after 10 AM?", choices: ["1 AM","1 PM","3 AM","3 PM"], answer: "1 PM", hint: "10 AM + 3 hours = 13:00 = 1:00 PM."),
            ]
        )
    case "algenubi":
        return LessonContent(
            intro: "Time words tell us WHEN things happen. Words like before, after, first, next, last, earlier, and later help us put events in order! 💬",
            exampleQuestion: "Which word means happening before something else?",
            exampleAnswer: "Earlier or Before",
            exampleViz: "earlier → now → later",
            problems: [
                .mc("Recess is AFTER lunch. If lunch is at noon, recess is…", choices: ["Before noon","After noon","At midnight"], answer: "After noon", hint: "'After' lunch means it comes next."),
                .mc("Which word means the OPPOSITE of 'before'?", choices: ["Earlier","During","After","Always"], answer: "After", hint: "Before ↔ After are opposites in time."),
                .mc("Kim did homework FIRST, then watched TV. The homework came…", choices: ["After TV","Before TV","During TV"], answer: "Before TV", hint: "First = before everything else."),
                .mc("Which sequence is correct?", choices: ["Wake up, sleep, eat breakfast","Eat breakfast, wake up, sleep","Wake up, eat breakfast, sleep"], answer: "Wake up, eat breakfast, sleep", hint: "Think about your real morning routine!"),
            ]
        )
    case "coins":
        return LessonContent(
            intro: "US coins: penny = 1¢, nickel = 5¢, dime = 10¢, quarter = 25¢. Count coins by starting with the biggest and working down! 🪙",
            exampleQuestion: "How much is 1 quarter + 1 dime + 1 penny?",
            exampleAnswer: "36¢  (25 + 10 + 1)",
            exampleViz: "Quarter 25¢ · Dime 10¢ · Nickel 5¢ · Penny 1¢",
            problems: [
                .mc("How many cents is a nickel worth?", choices: ["1¢","5¢","10¢","25¢"], answer: "5¢", hint: "Nickel = 5 cents."),
                .mc("You have 2 dimes and 3 pennies. Total?", choices: ["23¢","13¢","15¢","22¢"], answer: "23¢", hint: "2×10=20, then 20+3=23."),
                .input("How many nickels make 25 cents?", answer: "5", hint: "25 ÷ 5 = ?"),
                .mc("Which group equals exactly 50¢?", choices: ["1 quarter + 2 dimes","2 quarters","4 dimes + 2 nickels","All of the above"], answer: "2 quarters", hint: "2 × 25¢ = 50¢ exactly."),
            ]
        )
    case "change":
        return LessonContent(
            intro: "Making change = figuring out how much money you get BACK after paying. Subtract: Change = Amount paid − Price. Or count UP from the price! 💱",
            exampleQuestion: "A comic costs 65¢. You pay with $1. How much change do you get?",
            exampleAnswer: "35¢  ($1.00 − $0.65 = $0.35)",
            exampleViz: "65¢ → 70¢ → $1.00 = 35¢ change",
            problems: [
                .mc("A drink costs $1.25. You pay $2.00. Change?", choices: ["75¢","85¢","$1.25","65¢"], answer: "75¢", hint: "$2.00 − $1.25 = $0.75."),
                .mc("Sticker costs 45¢. You give 50¢. Change?", choices: ["5¢","10¢","15¢","95¢"], answer: "5¢", hint: "50 − 45 = 5."),
                .input("A book costs $3.60. You pay $5.00. Change in cents?", answer: "140", hint: "$5.00 − $3.60 = $1.40 = 140¢."),
                .mc("Best way to make 37¢ change using fewest coins?", choices: ["37 pennies","1 quarter + 1 dime + 2 pennies","3 dimes + 1 nickel + 2 pennies","7 nickels + 2 pennies"], answer: "1 quarter + 1 dime + 2 pennies", hint: "25+10+2=37 in only 4 coins!"),
            ]
        )
    case "dollar":
        return LessonContent(
            intro: "100 cents = 1 dollar. We write dollars with a $ sign and a decimal point: $1.25 means 1 dollar and 25 cents. Line up the decimal when adding! 💵",
            exampleQuestion: "What is $2.50 + $1.75?",
            exampleAnswer: "$4.25",
            exampleViz: "$2.50\n+$1.75\n———\n$4.25",
            problems: [
                .mc("How many cents is $1.05?", choices: ["15¢","150¢","105¢","10¢"], answer: "105¢", hint: "1 dollar = 100¢, plus 5¢ = 105¢."),
                .mc("$3.99 + $2.01 = ?", choices: ["$5.00","$6.00","$5.99","$4.00"], answer: "$6.00", hint: "$3.99 + $2.01 = $6.00 exactly."),
                .input("You have $10.00. You spend $6.45. How much is left? (enter dollars and cents like 3.55)", answer: "3.55", hint: "$10.00 − $6.45 = $3.55."),
                .mc("Which is the greatest amount?", choices: ["$4.99","$4.09","$5.01","$4.90"], answer: "$5.01", hint: "Compare the dollars first: $5 beats all the $4 amounts."),
            ]
        )
    case "phon":
        return LessonContent(
            intro: "PHONICS is knowing what sounds letters make. Blends like 'bl', 'str' combine sounds. Digraphs like 'sh', 'ch', 'th' make ONE new sound together! 🔤",
            exampleQuestion: "What sound does 'sh' make in the word 'ship'?",
            exampleAnswer: "One sound: /sh/ — like shushing someone!",
            exampleViz: "sh → /ʃ/ · ch → /tʃ/ · th → /ð/",
            problems: [
                .mc("Which word starts with the /bl/ blend?", choices: ["bread","black","bright","bring"], answer: "black", hint: "'bl' blend: b + l together at the start."),
                .mc("The letters 'ch' in 'chair' make one sound. This is called a…", choices: ["Blend","Digraph","Vowel","Syllable"], answer: "Digraph", hint: "A digraph is 2 letters that make 1 sound."),
                .mc("How many syllables in 'butterfly'?", choices: ["2","3","4","5"], answer: "3", hint: "But-ter-fly = 3 claps."),
                .mc("Which word has a LONG vowel sound?", choices: ["cap","hop","cake","cut"], answer: "cake", hint: "Long vowel says its name! 'Cake' has the long /ā/ sound."),
            ]
        )
    case "sight":
        return LessonContent(
            intro: "Sight words are super-common words you should RECOGNIZE on sight without sounding out, like: the, said, where, because, they, through. ⚡👀",
            exampleQuestion: "Which of these is a sight word you just have to memorize?",
            exampleAnswer: "Words like 'said', 'the', 'because' — they don't always follow phonics rules!",
            exampleViz: "the · said · was · they · where",
            problems: [
                .mc("Which sentence uses the sight word 'because' correctly?", choices: ["I stayed because it was raining.","Because I stayed it raining.","It because raining stayed I."], answer: "I stayed because it was raining.", hint: "'Because' explains the reason for something."),
                .mc("Pick the correct sight word: 'She ___ the cat was hiding.'", choices: ["knowed","knews","knew","know"], answer: "knew", hint: "'Knew' is the past tense of 'know' — a tricky sight word!"),
                .mc("Which sight word completes: 'He went ___ the tunnel.'", choices: ["threw","through","though","tough"], answer: "through", hint: "'Through' = from one side to the other."),
                .mc("Which is spelled correctly?", choices: ["becaus","becuase","because","becasue"], answer: "because", hint: "Be-cause: b-e-c-a-u-s-e."),
            ]
        )
    case "flu":
        return LessonContent(
            intro: "FLUENT reading means smooth, expressive, not choppy. Read at a good pace, use punctuation as your guide — pause at commas, stop at periods! 🌊",
            exampleQuestion: "Why should you pause when you see a comma?",
            exampleAnswer: "A comma shows a natural pause — it helps meaning and expression!",
            exampleViz: "Fast & choppy ❌ · Smooth & expressive ✅",
            problems: [
                .mc("Which reading sounds more fluent?", choices: ["'The-dog-ran-fast.' (robot pace)","'The dog ran fast!' (natural pace)"], answer: "'The dog ran fast!' (natural pace)", hint: "Fluent reading sounds natural, like talking."),
                .mc("When you see an exclamation mark (!), you should read with…", choices: ["A quiet voice","Excitement or emphasis","A question tone","A very slow pace"], answer: "Excitement or emphasis", hint: "! = strong feeling or excitement."),
                .mc("Re-reading a tricky sentence helps with…", choices: ["Speed only","Comprehension and fluency","Spelling","Punctuation"], answer: "Comprehension and fluency", hint: "Going back helps you understand AND read more smoothly next time."),
                .mc("A question mark (?) tells you to read with a…", choices: ["Falling voice","Rising voice at the end","Very loud voice","Whisper"], answer: "Rising voice at the end", hint: "Questions typically go UP at the end."),
            ]
        )
    case "detail":
        return LessonContent(
            intro: "KEY DETAILS are the important facts in a text that SUPPORT the main idea. Ask: WHO, WHAT, WHERE, WHEN, WHY, HOW to find them! 🔍",
            exampleQuestion: "The passage says 'Dolphins communicate using clicks and whistles.' What is the key detail?",
            exampleAnswer: "Dolphins use clicks and whistles to communicate.",
            exampleViz: "Main idea ← supported by ← KEY DETAILS",
            problems: [
                .mc("'The cheetah can run 70 mph, making it the fastest land animal.' Key detail?", choices: ["Cheetahs are fast","Cheetahs run 70 mph","Cheetahs are animals","Animals run fast"], answer: "Cheetahs run 70 mph", hint: "The specific fact (70 mph) is the key detail."),
                .mc("Which question helps you find a KEY DETAIL?", choices: ["What is the whole story about?","What is the author's opinion?","What specific fact is given?","What is the title?"], answer: "What specific fact is given?", hint: "Details are specific facts, not the big picture."),
                .mc("A detail that SUPPORTS the main idea 'Trees are important' would be:", choices: ["Trees give oxygen to breathe","I like climbing trees","Trees are green","All plants grow"], answer: "Trees give oxygen to breathe", hint: "This specific fact supports why trees are important."),
                .mc("Where is a key detail usually found?", choices: ["Only in the title","In the body of the text","Only in the last paragraph","In the pictures only"], answer: "In the body of the text", hint: "Details are throughout the text — look for specific facts and examples."),
            ]
        )
    case "infer":
        return LessonContent(
            intro: "INFERENCE is reading the clues! Authors don't say everything — you use clues from the text PLUS what you already know to figure it out. 🕵️",
            exampleQuestion: "Maria put on her raincoat and grabbed her umbrella. What can you infer?",
            exampleAnswer: "It is raining or expected to rain outside.",
            exampleViz: "Clue + What I know → Inference",
            problems: [
                .mc("Jake's stomach growled. He looked at his watch — it was almost noon. What can you infer?", choices: ["Jake is tired","Jake is hungry and it's lunchtime","Jake is late for school","Jake has a stomachache"], answer: "Jake is hungry and it's lunchtime", hint: "Growling stomach + noon time = hungry at lunchtime."),
                .mc("The author NEVER says Tom is nervous, but he bites his nails and his hands shake. You can INFER…", choices: ["Tom is sick","Tom is nervous","Tom is cold","Tom is angry"], answer: "Tom is nervous", hint: "Biting nails + shaking hands are clues that suggest nervousness."),
                .mc("What do you use to make an inference?", choices: ["Only what the text says","Only your own experience","Text clues + your own knowledge","The title only"], answer: "Text clues + your own knowledge", hint: "Inference = clues from text + background knowledge."),
                .mc("'The classroom was empty and the hallways were dark.' You can infer it is…", choices: ["Recess time","A school day morning","After school hours","Lunchtime"], answer: "After school hours", hint: "Empty classroom + dark hallways = school is over."),
            ]
        )
    case "theme":
        return LessonContent(
            intro: "A THEME is the BIG LIFE MESSAGE of a story — like 'Be kind', 'Never give up', or 'Friends help each other'. It's different from the plot (what happens)! 🎭",
            exampleQuestion: "A story shows a girl who practices piano every day and finally wins a competition. What is the theme?",
            exampleAnswer: "Hard work pays off / Practice makes perfect.",
            exampleViz: "Plot: what happens → Theme: life lesson",
            problems: [
                .mc("A story: Two friends fight, but forgive each other. Theme?", choices: ["Friends can disagree","Fighting is wrong","Forgiveness keeps friendships strong","Best friends never fight"], answer: "Forgiveness keeps friendships strong", hint: "The message is about the VALUE of forgiving."),
                .mc("'Tortoise and the Hare' theme?", choices: ["Fast animals are better","Slow animals win races","Slow and steady wins the race","Turtles beat rabbits"], answer: "Slow and steady wins the race", hint: "The tortoise's perseverance beat the hare's quickness."),
                .mc("How is theme DIFFERENT from the main idea?", choices: ["They are the same thing","Theme is a life lesson; main idea is what the text is mostly about","Theme is a fact; main idea is a lesson","Theme is for fiction; main idea is for nonfiction"], answer: "Theme is a life lesson; main idea is what the text is mostly about", hint: "Theme = message about life. Main idea = what the piece covers."),
                .mc("Which is a THEME (not a topic)?", choices: ["The story is about a dog","A dog helps a family through hard times","Kindness can change a life","Dogs are pets"], answer: "Kindness can change a life", hint: "Topics are nouns. Themes are lessons phrased as full ideas."),
            ]
        )
    case "caps":
        return LessonContent(
            intro: "Every sentence STARTS with a CAPITAL letter and ENDS with punctuation (. ! or ?). Names of people, places, and months are always capitalized. 🔠",
            exampleQuestion: "Fix this sentence: the cat sat on the mat.",
            exampleAnswer: "The cat sat on the mat.",
            exampleViz: "Capital at start · Punctuation at end",
            problems: [
                .mc("Which sentence is punctuated correctly?", choices: ["the dog barked.","The dog barked.","The dog barked","the dog barked"], answer: "The dog barked.", hint: "Capital T at start, period at end."),
                .mc("Which word should be capitalized?", choices: ["monday","apple","run","blue"], answer: "monday", hint: "Days of the week are proper nouns — always capitalized!"),
                .mc("Which sentence ends with the right punctuation?", choices: ["Did she win?","Did she win.","Did she win!","Did she win"], answer: "Did she win?", hint: "Questions end with a question mark."),
                .mc("Which name is capitalized correctly?", choices: ["new York","new york","New York","New york"], answer: "New York", hint: "Both words in a proper name are capitalized."),
            ]
        )
    case "noun":
        return LessonContent(
            intro: "A NOUN is a person, place, or thing (and ideas too!). A VERB shows action or state: run, jump, is, feel. Every sentence needs both! 🐶",
            exampleQuestion: "In 'The rabbit HOPS through the garden.' — which word is the verb?",
            exampleAnswer: "HOPS — it shows the action!",
            exampleViz: "Noun = person/place/thing · Verb = action/state",
            problems: [
                .mc("Which word is a NOUN?", choices: ["Jump","Quickly","Pizza","Beautiful"], answer: "Pizza", hint: "Nouns are people, places, or things. Pizza is a thing!"),
                .mc("Which word is a VERB?", choices: ["Happy","Mountain","Climb","Slowly"], answer: "Climb", hint: "Verbs show action. Climbing is an action!"),
                .mc("'The pilot FLEW the airplane.' The noun is…", choices: ["Flew","The","Pilot","Fast"], answer: "Pilot", hint: "Pilot is a person — a noun!"),
                .mc("Which sentence has both a noun AND a verb?", choices: ["Running fast!","The bird sings.","Beautiful music","Quickly now!"], answer: "The bird sings.", hint: "Bird (noun) + sings (verb) = complete thought."),
            ]
        )
    case "sent":
        return LessonContent(
            intro: "A COMPLETE sentence has a SUBJECT (who/what) and a PREDICATE (what it does or is). 'The dog barked.' ✅  'The dog.' ❌ (no action!) 📝",
            exampleQuestion: "Is 'Running in the park.' a complete sentence?",
            exampleAnswer: "NO — we don't know WHO is running. It's a fragment!",
            exampleViz: "Subject + Predicate = Complete sentence ✅",
            problems: [
                .mc("Which is a COMPLETE sentence?", choices: ["After the game.","The kids cheered loudly.","Jumping very high!","Because it was cold."], answer: "The kids cheered loudly.", hint: "It has a subject (The kids) and a predicate (cheered loudly)."),
                .mc("'Swims every morning.' is a sentence fragment because…", choices: ["It's too short","It has no subject — we don't know WHO swims","It has no verb","It has no period"], answer: "It has no subject — we don't know WHO swims", hint: "Fragments are missing the subject or verb."),
                .mc("How do you fix 'The tiny brown rabbit.' into a complete sentence?", choices: ["Add a period","Add a verb — 'The tiny brown rabbit nibbled grass.'","Add 'I saw' at the end","Capitalize rabbit"], answer: "Add a verb — 'The tiny brown rabbit nibbled grass.'", hint: "Add what the subject DOES."),
                .mc("A run-on sentence is…", choices: ["A sentence that's too short","Two sentences jammed together without punctuation","A sentence with a verb","A question"], answer: "Two sentences jammed together without punctuation", hint: "Fix a run-on with a period, comma, or semicolon."),
            ]
        )
    case "adj":
        return LessonContent(
            intro: "ADJECTIVES describe NOUNS — they answer: WHAT KIND? HOW MANY? WHICH ONE? They paint a picture with words! 'The TINY, BLUE butterfly.' 🌈",
            exampleQuestion: "In 'the red ball', which word is the adjective?",
            exampleAnswer: "red — it describes what KIND of ball.",
            exampleViz: "big, small, happy, three, cloudy, soft…",
            problems: [
                .mc("Which word is an ADJECTIVE?", choices: ["Run","Loudly","Fluffy","Quickly"], answer: "Fluffy", hint: "Fluffy describes what something looks or feels like."),
                .mc("'She carried a heavy backpack.' The adjective is…", choices: ["She","Carried","Heavy","Backpack"], answer: "Heavy", hint: "Heavy describes the backpack."),
                .mc("Add an adjective: 'The ___ dragon breathed fire.'", choices: ["Ferocious","Quickly","Running","And"], answer: "Ferocious", hint: "Which word describes what the dragon is LIKE?"),
                .mc("Which sentence has TWO adjectives?", choices: ["The cat runs.","The fluffy, orange cat purrs.","She ran quickly.","Birds fly high."], answer: "The fluffy, orange cat purrs.", hint: "Fluffy and orange both describe the cat."),
            ]
        )
    case "para":
        return LessonContent(
            intro: "A PARAGRAPH is a group of sentences about ONE idea. It has: a TOPIC SENTENCE (main point), SUPPORTING DETAILS (proof/examples), and a CLOSING SENTENCE. 📄",
            exampleQuestion: "What does the topic sentence do in a paragraph?",
            exampleAnswer: "It states the MAIN POINT — what the whole paragraph is about.",
            exampleViz: "Topic sentence → Details → Closing",
            problems: [
                .mc("Where is the topic sentence usually found?", choices: ["At the very end","In the middle","At the beginning","In the title"], answer: "At the beginning", hint: "The topic sentence introduces the paragraph's main idea."),
                .mc("Which is a good TOPIC sentence for a paragraph about dogs?", choices: ["Dogs have four legs.","Dogs are one of the best animal companions for many reasons.","Woof!","I saw a dog yesterday."], answer: "Dogs are one of the best animal companions for many reasons.", hint: "A topic sentence introduces a broad idea that the paragraph will support."),
                .mc("A paragraph about soccer would NOT include…", choices: ["How to kick the ball","Rules of the game","Soccer field size","How to bake a cake"], answer: "How to bake a cake", hint: "Stay on topic! Baking has nothing to do with soccer."),
                .mc("The CLOSING sentence of a paragraph should…", choices: ["Introduce a new topic","Repeat the title","Wrap up or restate the main idea","List all the details again"], answer: "Wrap up or restate the main idea", hint: "The closing ties a bow on the paragraph."),
            ]
        )
    case "story":
        return LessonContent(
            intro: "Every great story has a BEGINNING (introduce characters & setting), MIDDLE (the problem/adventure), and END (the solution/conclusion). 🏰",
            exampleQuestion: "Where in a story is the 'problem' or conflict usually introduced?",
            exampleAnswer: "The MIDDLE — that's where the action and challenges happen!",
            exampleViz: "Beginning → Middle (problem) → End (solution)",
            problems: [
                .mc("The characters and setting are introduced in the…", choices: ["Middle","End","Beginning","Climax"], answer: "Beginning", hint: "The beginning sets the stage for the story."),
                .mc("The most exciting or tense moment in a story is called the…", choices: ["Introduction","Climax","Resolution","Setting"], answer: "Climax", hint: "The climax is the peak — the highest point of tension!"),
                .mc("'They all lived happily ever after.' This is from the story's…", choices: ["Beginning","Middle","End","Introduction"], answer: "End", hint: "The ending wraps up what happens after the problem is solved."),
                .mc("A character who faces a problem and grows from it is called a…", choices: ["Narrator","Protagonist","Antagonist","Setting"], answer: "Protagonist", hint: "The protagonist is the main character — usually the hero!"),
            ]
        )
    case "opin":
        return LessonContent(
            intro: "Opinion writing shares YOUR POINT OF VIEW. State your opinion, give REASONS with EVIDENCE, and end with a CONCLUSION. Use words like: I think, I believe, In my opinion! 💭",
            exampleQuestion: "How is an OPINION different from a FACT?",
            exampleAnswer: "A fact is always true for everyone. An opinion is what YOU think or feel — others may disagree!",
            exampleViz: "Fact: Earth orbits the Sun ✅ · Opinion: Summer is the best season 💭",
            problems: [
                .mc("Which statement is an OPINION?", choices: ["Water boils at 100°C.","Dogs are better pets than cats.","The Earth has one moon.","7 × 8 = 56."], answer: "Dogs are better pets than cats.", hint: "This is what SOME people think — others might disagree!"),
                .mc("Which is a FACT?", choices: ["Pizza is delicious.","School is boring.","The Pacific is the largest ocean.","Summer is better than winter."], answer: "The Pacific is the largest ocean.", hint: "This can be verified — it's always true."),
                .mc("Which is the BEST opening for an opinion paragraph?", choices: ["One day I went to the park.","I believe homework should be shorter because it causes stress.","Homework.","Is homework good or bad?"], answer: "I believe homework should be shorter because it causes stress.", hint: "A strong opinion opener states your view AND hints at the reason."),
                .mc("A REASON supports your opinion. Which is a good reason for 'School should start later'?", choices: ["Some kids don't like waking up","Teenagers need more sleep and learn better when rested","School is too long","I don't like mornings"], answer: "Teenagers need more sleep and learn better when rested", hint: "Give evidence — not just 'I don't like it'!"),
            ]
        )
    case "edit":
        return LessonContent(
            intro: "EDITING is fixing mistakes in writing: spelling, punctuation, capitalization, grammar. Good writers ALWAYS re-read and edit their work! 🧹",
            exampleQuestion: "Find the mistake: 'she went two the store.'",
            exampleAnswer: "Two errors: 'she' → 'She' (capital) and 'two' → 'to' (wrong word).",
            exampleViz: "CUPS: Capitalization · Usage · Punctuation · Spelling",
            problems: [
                .mc("Find the spelling mistake: 'The wether was verry hot.'", choices: ["wether → weather and verry → very","wether is fine","verry is correct","No mistakes"], answer: "wether → weather and verry → very", hint: "Weather and very are commonly misspelled."),
                .mc("Fix the punctuation: 'Is she coming to the party'", choices: ["Add a period","Add a question mark","Add an exclamation mark","No change needed"], answer: "Add a question mark", hint: "It's a question — so it needs a '?'."),
                .mc("Which is the correct edit for 'i went to new york last july'?", choices: ["I went to New York last July.","i went to New York last July.","I went to new york last july.","I went to New York last july."], answer: "I went to New York last July.", hint: "Capitalize: 'I', 'New York' (proper noun), 'July' (month name)."),
                .mc("What does CUPS stand for in editing?", choices: ["Capitals, Understanding, Periods, Sentences","Capitalization, Usage, Punctuation, Spelling","Commas, Using, Points, Spelling","Copy, Underline, Proofread, Submit"], answer: "Capitalization, Usage, Punctuation, Spelling", hint: "CUPS is a common editing checklist!"),
            ]
        )
    case "living":
        return LessonContent(
            intro: "Living things GROW, need energy, RESPOND to their environment, and REPRODUCE. Non-living things do NONE of these. A rock? Non-living. A mushroom? Living! 🌱",
            exampleQuestion: "Does a rock grow? Does it need food? Is it living?",
            exampleAnswer: "NO — rocks don't grow, eat, or reproduce. Non-living!",
            exampleViz: "Living: grow · eat · respond · reproduce",
            problems: [
                .mc("Which of these is LIVING?", choices: ["Cloud","Bicycle","Fern","River"], answer: "Fern", hint: "Ferns grow, reproduce, and respond to light — they're alive!"),
                .mc("Fire needs oxygen and 'grows' — is it living?", choices: ["Yes, fire is alive","No, fire cannot reproduce or have cells","Only big fires are living","Fire is sort of living"], answer: "No, fire cannot reproduce or have cells", hint: "Living things have cells and can reproduce. Fire does neither."),
                .mc("Which is a characteristic of ALL living things?", choices: ["They can move","They are made of cells","They live in water","They have a brain"], answer: "They are made of cells", hint: "All living things — plants, animals, bacteria — are made of cells."),
                .mc("A cactus doesn't move. Is it living?", choices: ["No, because it can't move","Yes, it grows, reproduces, and responds to sunlight","Only if it makes fruit","Plants are not living things"], answer: "Yes, it grows, reproduces, and responds to sunlight", hint: "Movement is NOT required to be alive. Plants are definitely living!"),
            ]
        )
    case "plant":
        return LessonContent(
            intro: "Plants have ROOTS (drink water, anchor), STEMS (carry water up), LEAVES (make food with sunlight), and FLOWERS/SEEDS (reproduction). Each part has a job! 🌻",
            exampleQuestion: "Which plant part absorbs water from the soil?",
            exampleAnswer: "The ROOTS!",
            exampleViz: "🌻 flower · 🌿 leaf · 🌲 stem · 🌱 roots",
            problems: [
                .mc("Which plant part carries water and nutrients from roots to leaves?", choices: ["Flower","Stem","Leaf","Seed"], answer: "Stem", hint: "The stem is like a straw — it transports water up."),
                .mc("Where does a plant make most of its food (photosynthesis)?", choices: ["Roots","Stem","Flower","Leaves"], answer: "Leaves", hint: "Leaves are green because of chlorophyll — which captures sunlight for food-making."),
                .mc("What is the main job of a flower?", choices: ["Make food","Hold the plant up","Reproduce — make seeds","Absorb water"], answer: "Reproduce — make seeds", hint: "Flowers attract pollinators and produce seeds for reproduction."),
                .mc("A plant without roots would struggle because…", choices: ["It couldn't make food","It couldn't absorb water or anchor itself","It couldn't reproduce","It couldn't use sunlight"], answer: "It couldn't absorb water or anchor itself", hint: "Roots do two big jobs: drink water AND hold the plant in place."),
            ]
        )
    case "animal":
        return LessonContent(
            intro: "Animals are sorted into groups: MAMMALS (fur, live birth, nurse young), BIRDS (feathers, beaks), REPTILES (scales, cold-blooded), AMPHIBIANS (live in water AND land), FISH (gills, fins)! 🦁",
            exampleQuestion: "What makes a mammal a mammal?",
            exampleAnswer: "Mammals have fur/hair, give live birth, and nurse their young with milk.",
            exampleViz: "Mammal 🦁 · Bird 🐦 · Reptile 🦎 · Amphibian 🐸 · Fish 🐟",
            problems: [
                .mc("A frog is an amphibian because…", choices: ["It lives only in water","It has scales","It can live in water AND on land","It lays eggs with shells"], answer: "It can live in water AND on land", hint: "Amphibian = both water and land!"),
                .mc("Which animal is a REPTILE?", choices: ["Whale","Eagle","Crocodile","Salamander"], answer: "Crocodile", hint: "Reptiles have dry scales and are cold-blooded."),
                .mc("Which is a MAMMAL?", choices: ["Salmon","Penguin","Bat","Frog"], answer: "Bat", hint: "Bats have fur, give live birth, and nurse with milk — they're mammals!"),
                .mc("Birds and reptiles both…", choices: ["Are warm-blooded","Have feathers","Lay eggs","Live in water"], answer: "Lay eggs", hint: "Both groups lay eggs — though they look very different!"),
            ]
        )
    case "food":
        return LessonContent(
            intro: "A FOOD CHAIN shows who eats whom! PRODUCERS (plants) → CONSUMERS (animals that eat plants or other animals) → DECOMPOSERS (break down waste). Energy flows up! 🦊",
            exampleQuestion: "In the food chain: Grass → Rabbit → Fox, who is the producer?",
            exampleAnswer: "GRASS — it produces food using sunlight (photosynthesis).",
            exampleViz: "☀️ → 🌿 Plant → 🐇 Herbivore → 🦊 Carnivore",
            problems: [
                .mc("A HERBIVORE eats only…", choices: ["Meat","Plants","Both plants and meat","Decomposed material"], answer: "Plants", hint: "Herbi = plant. Herbivores eat only plants."),
                .mc("In the food chain Grass→Grasshopper→Frog→Snake, the grasshopper is a…", choices: ["Producer","Primary consumer","Secondary consumer","Decomposer"], answer: "Primary consumer", hint: "The first animal to eat the producer = primary consumer."),
                .mc("What would happen if all the plants in a food chain disappeared?", choices: ["Nothing would change","Only carnivores would be affected","All consumers would eventually lose their food source","Only herbivores would die"], answer: "All consumers would eventually lose their food source", hint: "Plants are the base — remove them and the whole chain collapses!"),
                .mc("Mushrooms and bacteria are DECOMPOSERS. They…", choices: ["Hunt other animals","Make food from sunlight","Break down dead organisms and recycle nutrients","Eat only plants"], answer: "Break down dead organisms and recycle nutrients", hint: "Decomposers are nature's recyclers!"),
            ]
        )
    case "cycle":
        return LessonContent(
            intro: "A LIFE CYCLE is the stages a living thing goes through in its life. A butterfly: egg → caterpillar → chrysalis → butterfly. This is called METAMORPHOSIS! 🦋",
            exampleQuestion: "What are the 4 stages of a butterfly's life cycle?",
            exampleAnswer: "Egg → Larva (caterpillar) → Pupa (chrysalis) → Adult (butterfly)",
            exampleViz: "🥚 → 🐛 → 🫘 → 🦋",
            problems: [
                .mc("Which stage comes AFTER the egg in a butterfly's life cycle?", choices: ["Adult","Chrysalis","Larva (caterpillar)","Pupa"], answer: "Larva (caterpillar)", hint: "Egg hatches into a larva (the caterpillar)."),
                .mc("A frog's life cycle: egg → tadpole → froglet → frog. 'Tadpole' stage has…", choices: ["Legs and lungs","A tail and gills for water breathing","Feathers","Wings"], answer: "A tail and gills for water breathing", hint: "Tadpoles live fully in water and breathe through gills."),
                .mc("Complete metamorphosis is different from incomplete because…", choices: ["Complete has 4 stages including a pupa; incomplete has 3 stages (no pupa)","Complete is faster","Incomplete goes egg-larva-adult","Both are the same"], answer: "Complete has 4 stages including a pupa; incomplete has 3 stages (no pupa)", hint: "Grasshoppers do incomplete (3 stages); butterflies complete (4 stages)."),
                .mc("How is a plant's life cycle similar to an animal's?", choices: ["Plants don't have life cycles","Both start from a seed","Both start from an egg","Both have a larva stage"], answer: "Both start from a seed", hint: "Both start as a single 'starter unit' — seed for plants, egg for most animals."),
            ]
        )
    case "eco":
        return LessonContent(
            intro: "An ECOSYSTEM is all the living things (BIOTIC) AND non-living things (ABIOTIC: water, sunlight, soil, air) in a place — all interacting together! 🐝",
            exampleQuestion: "Name one biotic and one abiotic part of a forest ecosystem.",
            exampleAnswer: "Biotic: a tree 🌲. Abiotic: sunlight ☀️.",
            exampleViz: "Biotic: plants, animals · Abiotic: water, sunlight, soil",
            problems: [
                .mc("Which is an ABIOTIC factor in an ecosystem?", choices: ["Rabbit","Oak tree","Temperature","Mushroom"], answer: "Temperature", hint: "Abiotic = non-living. Temperature is not alive."),
                .mc("If a river dries up in a forest ecosystem, what most likely happens?", choices: ["Nothing changes","Animals find more food","Many plants and animals lose a water source and populations decline","Plants grow faster"], answer: "Many plants and animals lose a water source and populations decline", hint: "Water is an abiotic factor everything depends on."),
                .mc("Which word describes ALL living parts of an ecosystem?", choices: ["Abiotic","Biotic","Climate","Habitat"], answer: "Biotic", hint: "Bio = life. Biotic = living parts."),
                .mc("Bees pollinate flowers in a meadow ecosystem. If bees disappeared, what might happen?", choices: ["More flowers would grow","Flowers couldn't reproduce and populations might drop","Bees don't affect flowers","Nothing would change"], answer: "Flowers couldn't reproduce and populations might drop", hint: "Bees carry pollen between flowers — without them, many plants can't make seeds."),
            ]
        )
    case "photo":
        return LessonContent(
            intro: "PHOTOSYNTHESIS is how plants make food! They use SUNLIGHT + WATER + CARBON DIOXIDE → GLUCOSE (sugar for energy) + OXYGEN. You breathe the oxygen! ☀️",
            exampleQuestion: "What 3 ingredients does a plant need for photosynthesis?",
            exampleAnswer: "Sunlight, water, and carbon dioxide (CO₂).",
            exampleViz: "☀️ + 💧 + CO₂ → 🍬 glucose + O₂",
            problems: [
                .mc("What gas do plants RELEASE during photosynthesis?", choices: ["Carbon dioxide","Water vapor","Oxygen","Nitrogen"], answer: "Oxygen", hint: "Plants take in CO₂ and release O₂ — the oxygen we breathe!"),
                .mc("Where in a plant does photosynthesis mainly happen?", choices: ["Roots","Stem","Flower","Leaves"], answer: "Leaves", hint: "Leaves are green because of chlorophyll, the molecule that captures sunlight."),
                .mc("A plant kept in a dark closet for a week would…", choices: ["Grow faster","Stay the same","Wilt and eventually die without light for photosynthesis","Make more oxygen"], answer: "Wilt and eventually die without light for photosynthesis", hint: "No light = no food-making = plant starves."),
                .mc("What does chlorophyll do?", choices: ["Absorbs water","Captures sunlight for photosynthesis","Makes flowers colorful","Holds roots in soil"], answer: "Captures sunlight for photosynthesis", hint: "Chlorophyll is the green pigment that traps light energy."),
            ]
        )
    case "zeta":
        return LessonContent(
            intro: "CELLS are the tiny building blocks of all living things! Plants have a rigid CELL WALL. Both plants and animals have a CELL MEMBRANE, NUCLEUS (control center), and CYTOPLASM (gel filling). 🔬",
            exampleQuestion: "What is the 'control center' of a cell called?",
            exampleAnswer: "The NUCLEUS — it holds DNA and directs the cell's activities.",
            exampleViz: "Nucleus 🔵 · Membrane 🟡 · Cytoplasm 🌊",
            problems: [
                .mc("Which cell part controls everything the cell does?", choices: ["Cell wall","Cytoplasm","Nucleus","Membrane"], answer: "Nucleus", hint: "The nucleus holds DNA — the instructions for life."),
                .mc("Which structure is found in PLANT cells but NOT animal cells?", choices: ["Nucleus","Cell membrane","Cell wall","Cytoplasm"], answer: "Cell wall", hint: "Plants have a rigid cell wall for structure. Animal cells only have a membrane."),
                .mc("What does the cell membrane do?", choices: ["Makes energy","Controls what enters and leaves the cell","Stores DNA","Makes food"], answer: "Controls what enters and leaves the cell", hint: "The membrane is like a gatekeeper — it decides what passes in and out."),
                .mc("Which of these is an example of a unicellular (single-celled) organism?", choices: ["Dog","Oak tree","Bacteria","Mushroom"], answer: "Bacteria", hint: "Most bacteria are made of just one cell!"),
            ]
        )
    case "shaula":
        return LessonContent(
            intro: "ADAPTATIONS are special features or behaviors that help an animal SURVIVE in its environment. Sharp claws, camouflage, migration, thick fur — all adaptations! 🐾",
            exampleQuestion: "Why does a polar bear have thick white fur?",
            exampleAnswer: "White fur = camouflage in snow. Thick fur = insulation from the cold. Both are adaptations!",
            exampleViz: "Adaptation → Survival advantage",
            problems: [
                .mc("A cactus stores water in its thick stem. This is an adaptation for…", choices: ["Cold weather","Living underground","Surviving in dry deserts","Attracting insects"], answer: "Surviving in dry deserts", hint: "Storing water helps the cactus survive long dry spells."),
                .mc("A stick insect looks exactly like a twig. This adaptation is called…", choices: ["Migration","Camouflage","Hibernation","Venom"], answer: "Camouflage", hint: "Camouflage = blending in with the surroundings."),
                .mc("Birds fly south for winter. This behavior is called…", choices: ["Hibernation","Camouflage","Migration","Adaptation"], answer: "Migration", hint: "Migration = seasonal movement to find better conditions."),
                .mc("A duck's webbed feet are an adaptation for…", choices: ["Climbing trees","Swimming","Digging burrows","Running fast"], answer: "Swimming", hint: "Webbed feet work like paddles — perfect for moving through water."),
            ]
        )
    case "lesath":
        return LessonContent(
            intro: "Animals have fascinating defense mechanisms! VENOM (scorpions, snakes), CAMOUFLAGE (chameleons), ARMOR (turtles), SPEED (cheetahs), and MIMICRY (pretending to be something dangerous). ⚡",
            exampleQuestion: "How does a skunk defend itself?",
            exampleAnswer: "It sprays a smelly liquid to drive predators away!",
            exampleViz: "Venom · Camouflage · Armor · Speed · Mimicry",
            problems: [
                .mc("A harmless king snake has stripes similar to a venomous coral snake. This defense is called…", choices: ["Camouflage","Mimicry","Venom","Armor"], answer: "Mimicry", hint: "Mimicry = copying the appearance of something dangerous."),
                .mc("Porcupines have sharp quills. This is an example of…", choices: ["Venom","Speed","Physical defense (armor/spines)","Mimicry"], answer: "Physical defense (armor/spines)", hint: "Quills are a passive physical defense — predators learn to avoid porcupines!"),
                .mc("A scorpion uses its stinger to inject…", choices: ["Camouflage","Venom","Silk","Ink"], answer: "Venom", hint: "Scorpion venom immobilizes prey and deters predators."),
                .mc("An octopus shoots ink when threatened. The ink helps the octopus…", choices: ["Attract mates","Confuse and escape from predators","Catch prey","Change color"], answer: "Confuse and escape from predators", hint: "The ink cloud distracts the predator, giving the octopus time to jet away!"),
            ]
        )
    case "sun":
        return LessonContent(
            intro: "The SUN is a star at the center of our solar system — ENORMOUS! Earth orbits the Sun. The Moon orbits Earth. The Moon's gravity causes TIDES! 🌞",
            exampleQuestion: "What does the Earth orbit around?",
            exampleAnswer: "The SUN — it takes Earth 365¼ days (1 year) to go all the way around.",
            exampleViz: "🌞 ← Earth orbits → 🌍 ← Moon orbits → 🌕",
            problems: [
                .mc("How long does Earth take to orbit the Sun?", choices: ["24 hours","1 month","365 days (1 year)","28 days"], answer: "365 days (1 year)", hint: "One trip around the Sun = 1 year!"),
                .mc("Why do we have day and night?", choices: ["Because the Moon blocks the Sun","Because Earth revolves around the Sun","Because Earth rotates on its axis every 24 hours","Because the Sun moves across the sky"], answer: "Because Earth rotates on its axis every 24 hours", hint: "Earth's ROTATION (spinning) causes day and night."),
                .mc("Which is the correct order from smallest to largest?", choices: ["Moon, Earth, Sun","Sun, Earth, Moon","Earth, Moon, Sun","Moon, Sun, Earth"], answer: "Moon, Earth, Sun", hint: "Moon is smallest; Sun is by far the largest."),
                .mc("What causes the Moon's phases?", choices: ["Earth's shadow always covers the Moon","The Moon changing size","The Moon's position relative to Earth and Sun","Clouds covering the Moon"], answer: "The Moon's position relative to Earth and Sun", hint: "We see different lit portions of the Moon as it orbits Earth."),
            ]
        )
    case "season":
        return LessonContent(
            intro: "Earth is TILTED on its axis (23.5°)! When the Northern Hemisphere tilts TOWARD the Sun → Summer. Tilted AWAY → Winter. This tilt causes the 4 seasons! 🍁",
            exampleQuestion: "Why is it summer in the Northern Hemisphere when it's winter in the Southern Hemisphere?",
            exampleAnswer: "Because the Northern Hemisphere is tilted toward the Sun while the Southern is tilted away.",
            exampleViz: "Earth tilt + orbit position = seasons",
            problems: [
                .mc("What causes seasons on Earth?", choices: ["Earth's distance from the Sun","Earth's tilted axis and position in its orbit","The Moon's gravity","The amount of rain"], answer: "Earth's tilted axis and position in its orbit", hint: "It's about TILT, not distance!"),
                .mc("During which season does the Northern Hemisphere receive the most direct sunlight?", choices: ["Winter","Spring","Summer","Fall"], answer: "Summer", hint: "More direct sunlight = more energy = warmer temperatures."),
                .mc("What season is it in Australia when the USA has winter?", choices: ["Winter","Spring","Summer","Fall"], answer: "Summer", hint: "Australia is in the Southern Hemisphere — seasons are reversed!"),
                .mc("How many seasons are there in a year?", choices: ["2","3","4","6"], answer: "4", hint: "Spring, Summer, Fall (Autumn), Winter."),
            ]
        )
    case "weather":
        return LessonContent(
            intro: "WEATHER is what the atmosphere is doing RIGHT NOW — sunny, rainy, windy, snowy. CLIMATE is the usual weather patterns over many years in a region. ⛅",
            exampleQuestion: "What is the difference between weather and climate?",
            exampleAnswer: "Weather = today's conditions. Climate = long-term typical weather patterns.",
            exampleViz: "Weather: today · Climate: average over years",
            problems: [
                .mc("'Phoenix, Arizona is usually hot and dry year-round.' This describes…", choices: ["Weather","Climate","Precipitation","A storm"], answer: "Climate", hint: "'Usually' over a long time = climate."),
                .mc("Cumulonimbus clouds bring…", choices: ["Clear skies","Light drizzle","Thunderstorms","Snow only"], answer: "Thunderstorms", hint: "Cumulonimbus = towering storm clouds that bring thunder and lightning!"),
                .mc("A meteorologist studies…", choices: ["Meteors from space","Weather and atmospheric conditions","Rocks and minerals","Ocean currents only"], answer: "Weather and atmospheric conditions", hint: "A meteorologist forecasts the weather!"),
                .input("Water falling from clouds is called precipitation. Name one type.", answer: "rain", hint: "Rain, snow, sleet, and hail are all types of precipitation."),
            ]
        )
    case "water":
        return LessonContent(
            intro: "The WATER CYCLE is Earth's water recycling system! EVAPORATION (water→vapor), CONDENSATION (vapor→cloud), PRECIPITATION (water falls), COLLECTION (water gathers), and repeat! 💧",
            exampleQuestion: "What is it called when water vapor cools and forms clouds?",
            exampleAnswer: "CONDENSATION!",
            exampleViz: "☀️→💧Evaporation → ☁️Condensation → 🌧️Precipitation → 💧Collection",
            problems: [
                .mc("The SUN drives the water cycle mainly by causing…", choices: ["Precipitation","Evaporation","Condensation","Collection"], answer: "Evaporation", hint: "The Sun's energy heats water and turns it into vapor — the first step!"),
                .mc("When clouds get too heavy with water, what happens?", choices: ["Evaporation","Condensation","Precipitation","Transpiration"], answer: "Precipitation", hint: "Precipitation = water falling from clouds as rain, snow, or hail."),
                .mc("Water vapor cooling into liquid droplets to form clouds is called…", choices: ["Evaporation","Runoff","Condensation","Infiltration"], answer: "Condensation", hint: "Condense = liquid forming from a gas."),
                .mc("Plants release water vapor through their leaves. This process is called…", choices: ["Transpiration","Evaporation","Condensation","Respiration"], answer: "Transpiration", hint: "Plants 'sweat' water through tiny pores called stomata."),
            ]
        )
    case "rocks":
        return LessonContent(
            intro: "There are 3 types of rocks! IGNEOUS (cooled from magma), SEDIMENTARY (layers of sediment pressed together — often have fossils!), METAMORPHIC (changed by heat & pressure). 🪨",
            exampleQuestion: "Granite forms when magma cools slowly. What type of rock is it?",
            exampleAnswer: "IGNEOUS — formed from cooled magma or lava.",
            exampleViz: "Igneous 🌋 · Sedimentary 📚 · Metamorphic 💎",
            problems: [
                .mc("Limestone forms from layers of shells and sand compressed over time. It is…", choices: ["Igneous","Sedimentary","Metamorphic","Volcanic"], answer: "Sedimentary", hint: "Layers of sediment = sedimentary rock. Often contains fossils!"),
                .mc("Which rock type is most likely to contain fossils?", choices: ["Igneous","Metamorphic","Sedimentary","All equally"], answer: "Sedimentary", hint: "Fossils form when organisms are buried in sediment layers."),
                .mc("Marble is limestone changed by extreme heat and pressure. Marble is…", choices: ["Igneous","Sedimentary","Metamorphic","Volcanic"], answer: "Metamorphic", hint: "Meta = change. Heat and pressure transform the rock."),
                .mc("The Rock Cycle describes how rocks…", choices: ["Only form in volcanoes","Are completely permanent","Can change from one type to another over time","Are all made of the same minerals"], answer: "Can change from one type to another over time", hint: "Rocks can melt, be buried, erode, and reform — it's a continuous cycle!"),
            ]
        )
    case "planet":
        return LessonContent(
            intro: "8 planets orbit our Sun! In order: Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune. Memory trick: My Very Excellent Mother Just Served Us Nachos! 🪐",
            exampleQuestion: "Which planet is known for its beautiful rings?",
            exampleAnswer: "SATURN — its rings are made of ice and rock!",
            exampleViz: "☿ ♀ 🌍 ♂ ♃ 🪐 ⛢ ♆",
            problems: [
                .mc("Which planet is closest to the Sun?", choices: ["Venus","Earth","Mercury","Mars"], answer: "Mercury", hint: "My = Mercury. First in line!"),
                .mc("Which is the LARGEST planet in our solar system?", choices: ["Saturn","Neptune","Earth","Jupiter"], answer: "Jupiter", hint: "Jupiter is so huge it could fit over 1,000 Earths inside!"),
                .mc("What separates the inner rocky planets from the outer gas giants?", choices: ["The Moon","The Asteroid Belt","Saturn's rings","The Milky Way"], answer: "The Asteroid Belt", hint: "The Asteroid Belt sits between Mars and Jupiter."),
                .input("How many planets are in our solar system?", answer: "8", hint: "Pluto was reclassified as a dwarf planet in 2006."),
            ]
        )
    case "gravity":
        return LessonContent(
            intro: "GRAVITY is a force that pulls objects toward each other. The more MASS an object has, the stronger its gravity. Earth's gravity keeps us on the ground — and keeps the Moon in orbit! 🍎",
            exampleQuestion: "Why does an apple fall DOWN when you drop it?",
            exampleAnswer: "Earth's gravity pulls it toward Earth's center!",
            exampleViz: "Mass → Gravity → Pull 🍎⬇️",
            problems: [
                .mc("On the Moon, gravity is about 1/6 of Earth's. If you weigh 60 lbs on Earth, you'd weigh about ___ lbs on the Moon.", choices: ["60 lbs","10 lbs","30 lbs","120 lbs"], answer: "10 lbs", hint: "60 ÷ 6 = 10. Less gravity = less weight!"),
                .mc("What keeps Earth in orbit around the Sun?", choices: ["Earth's spin","The Sun's gravity pulling on Earth","Magnetic force","Earth's gravity"], answer: "The Sun's gravity pulling on Earth", hint: "The Sun's massive gravity keeps all planets in orbit."),
                .mc("Which object has the STRONGEST gravitational pull?", choices: ["A marble","A car","Earth","The Sun"], answer: "The Sun", hint: "More mass = more gravity. The Sun is by far the most massive!"),
                .mc("In space far from any planet, a dropped pen would…", choices: ["Fall fast","Fall slowly","Float in place","Fly upward"], answer: "Float in place", hint: "In the near-zero gravity of deep space, there's nothing to pull it down."),
            ]
        )
    case "galaxy":
        return LessonContent(
            intro: "A STAR is a giant ball of hot gas (plasma) that produces light and heat through nuclear fusion. Our galaxy, the MILKY WAY, contains over 200 BILLION stars! 🌌",
            exampleQuestion: "What is our galaxy called?",
            exampleAnswer: "The Milky Way — and Earth is in one of its spiral arms!",
            exampleViz: "⭐ star · ☀️ our star (Sun) · 🌌 Milky Way galaxy",
            problems: [
                .mc("What is the closest star to Earth?", choices: ["Polaris","Sirius","The Sun","Betelgeuse"], answer: "The Sun", hint: "The Sun IS a star — the closest one to us!"),
                .mc("What shape is the Milky Way galaxy?", choices: ["Circular","Elliptical","Spiral","Irregular"], answer: "Spiral", hint: "The Milky Way is a barred spiral galaxy with curving arms."),
                .mc("Stars twinkle because…", choices: ["They flicker on and off","They are very small","Earth's atmosphere bends their light","They are too far away"], answer: "Earth's atmosphere bends their light", hint: "Turbulence in Earth's atmosphere causes the flickering effect."),
                .mc("How many stars are roughly in the Milky Way galaxy?", choices: ["Thousands","Millions","Billions","Trillions"], answer: "Billions", hint: "Over 200 billion stars — and that's just our galaxy!"),
            ]
        )
    case "ancient":
        return LessonContent(
            intro: "ANCIENT civilizations were early organized societies — Egypt, Mesopotamia, Greece, Rome, China, Maya — with cities, governments, writing, and art. 🏛️",
            exampleQuestion: "What ancient civilization built the pyramids?",
            exampleAnswer: "Ancient Egypt — the Great Pyramid of Giza was built around 2560 BCE!",
            exampleViz: "Egypt 🔺 · Greece 🏛️ · Rome ⚔️ · China 🐉",
            problems: [
                .mc("Ancient Mesopotamia is often called…", choices: ["The Land Down Under","The Cradle of Civilization","The New World","The Middle Kingdom"], answer: "The Cradle of Civilization", hint: "Mesopotamia was one of the earliest places humans formed cities and writing."),
                .mc("The ancient Greeks gave us…", choices: ["The Great Wall","Democracy and the Olympic Games","The printing press","Algebra"], answer: "Democracy and the Olympic Games", hint: "Ancient Greece introduced democratic ideas and the first Olympics in 776 BCE."),
                .mc("Which writing system did ancient Egyptians use?", choices: ["Alphabet","Hieroglyphics","Cuneiform","Pictographs only"], answer: "Hieroglyphics", hint: "Egyptian hieroglyphics combined pictures and symbols to represent words."),
                .mc("The ancient Silk Road connected…", choices: ["Europe and Africa","China and Europe/Middle East","North and South America","Egypt and Greece"], answer: "China and Europe/Middle East", hint: "Traders traveled the Silk Road carrying silk, spices, and ideas between East and West."),
            ]
        )
    case "rastaban":
        return LessonContent(
            intro: "SKY STORIES (myths) are tales ancient cultures told to explain the stars! Every constellation has a legend. The stars were their calendar and compass! ✨",
            exampleQuestion: "Why did ancient people make up stories about constellations?",
            exampleAnswer: "To explain natural events, remember seasons, navigate, and pass down cultural values.",
            exampleViz: "Stars → Stories → Culture → Memory",
            problems: [
                .mc("The ancient Greeks named the constellation Orion after…", choices: ["A god","A hunter from mythology","A king","A type of ship"], answer: "A hunter from mythology", hint: "Orion was a great hunter in Greek myth — Zeus placed him in the stars."),
                .mc("Why were star patterns important to ancient farmers?", choices: ["They made farms look pretty","Stars helped them know what season it was and when to plant/harvest","Stars brought rain","Farmers didn't use stars"], answer: "Stars helped them know what season it was and when to plant/harvest", hint: "The rising of certain stars signaled planting or harvest seasons."),
                .mc("Many Native American nations have stories about the Big Dipper as a…", choices: ["Dragon","Bear","River","Warrior"], answer: "Bear", hint: "Multiple Native American nations connect the Big Dipper stars to a bear story."),
                .mc("An 'origin myth' explains…", choices: ["How to navigate by stars","How something came to exist or began","The distance to a star","A historical battle"], answer: "How something came to exist or began", hint: "Origin myths = stories explaining how the world or phenomena were created."),
            ]
        )
    case "maps":
        return LessonContent(
            intro: "Maps are flat pictures of Earth! Key parts: TITLE (what it shows), LEGEND/KEY (symbol meanings), COMPASS ROSE (directions), SCALE (distances). N/S/E/W = cardinal directions! 🧭",
            exampleQuestion: "What does the LEGEND on a map show?",
            exampleAnswer: "The legend explains what each symbol or color on the map means.",
            exampleViz: "Title · Legend · Compass Rose · Scale",
            problems: [
                .mc("The compass rose on a map shows…", choices: ["How big the map is","The meaning of symbols","North, South, East, West directions","The history of the area"], answer: "North, South, East, West directions", hint: "A compass rose helps you orient the map."),
                .mc("On a map, a blue line usually represents…", choices: ["A mountain","A road","A river or body of water","A border"], answer: "A river or body of water", hint: "Blue = water on most maps."),
                .mc("A map scale of '1 inch = 100 miles' means that 3 inches on the map = ?", choices: ["100 miles","200 miles","300 miles","30 miles"], answer: "300 miles", hint: "3 × 100 = 300 miles."),
                .mc("Which direction is OPPOSITE to West?", choices: ["North","South","East","Southwest"], answer: "East", hint: "West ↔ East are opposites. North ↔ South are opposites."),
            ]
        )
    case "nu":
        return LessonContent(
            intro: "A TIMELINE shows events in order from EARLIEST to LATEST. Read left to right (or bottom to top). Dates help you see HOW LONG AGO events happened and what came BEFORE or AFTER. 📜",
            exampleQuestion: "On a timeline, what does it mean if one event is to the LEFT of another?",
            exampleAnswer: "It happened EARLIER (before) the event to the right.",
            exampleViz: "⬅️ Earlier — Timeline — Later ➡️",
            problems: [
                .mc("On a timeline: 1776 — 1865 — 1969. Which event happened most recently?", choices: ["1776","1865","1969","They're the same"], answer: "1969", hint: "Larger number = more recent year."),
                .mc("How many years passed between 1776 and 1876?", choices: ["76 years","100 years","175 years","200 years"], answer: "100 years", hint: "1876 − 1776 = 100 years."),
                .mc("Which is earlier: 500 BCE or 200 BCE?", choices: ["500 BCE","200 BCE","Same time"], answer: "500 BCE", hint: "BCE counts backward: 500 BCE is further back in time than 200 BCE."),
                .mc("On a timeline, what does an arrow at the right end usually mean?", choices: ["The timeline is complete","Time continues beyond what's shown","The last event was important","Nothing"], answer: "Time continues beyond what's shown", hint: "Arrows show that time keeps going!"),
            ]
        )
    case "native":
        return LessonContent(
            intro: "NATIVE PEOPLES (Indigenous peoples) lived in the Americas for thousands of years before European contact. Different nations had unique cultures, languages, traditions, and relationships with the land. 🪶",
            exampleQuestion: "What term describes the many nations of people who lived in North America before European arrival?",
            exampleAnswer: "Native Americans, Indigenous peoples, or First Peoples — many prefer their specific nation's name.",
            exampleViz: "Lakota · Cherokee · Navajo · Iroquois · Inuit · Maya…",
            problems: [
                .mc("The Iroquois Confederacy (Haudenosaunee) was a powerful alliance of…", choices: ["2 nations","5 (later 6) nations","10 nations","All Indigenous nations"], answer: "5 (later 6) nations", hint: "The Haudenosaunee started with 5 nations and added the Tuscarora as the 6th."),
                .mc("The Plains nations like the Lakota relied heavily on which animal?", choices: ["Salmon","Buffalo (bison)","Deer","Horse (originally)"], answer: "Buffalo (bison)", hint: "Buffalo provided food, clothing, shelter, and tools for Plains nations."),
                .mc("The forced removal of Cherokee and other nations is known as…", choices: ["The Oregon Trail","The Trail of Tears","The Santa Fe Trail","The Silk Road"], answer: "The Trail of Tears", hint: "The Trail of Tears was the forced removal of Cherokee and other nations from their homelands."),
                .mc("Why is it important to learn about Native peoples' histories and cultures?", choices: ["It's required by law","Their history is unimportant","Their contributions, traditions, and stories are part of American history and heritage","Only if you are Indigenous"], answer: "Their contributions, traditions, and stories are part of American history and heritage", hint: "Indigenous cultures have shaped North American history, language, food, and geography."),
            ]
        )
    case "explor":
        return LessonContent(
            intro: "In the 1400s–1600s, European EXPLORERS sailed to new lands seeking trade routes, riches, and glory. Columbus, Magellan, Cabot, and others changed the world — for better and worse. ⛵",
            exampleQuestion: "In what year did Christopher Columbus first reach the Americas?",
            exampleAnswer: "1492",
            exampleViz: "Columbus 1492 · Magellan 1519 · Da Gama 1498",
            problems: [
                .mc("Ferdinand Magellan's expedition was the first to…", choices: ["Reach Asia","Sail around the entire Earth","Find the Americas","Discover Australia"], answer: "Sail around the entire Earth", hint: "Magellan's voyage (1519–1522) was the first to circle the globe."),
                .mc("Columbus sailed for which country?", choices: ["Portugal","France","Spain","England"], answer: "Spain", hint: "Queen Isabella and King Ferdinand of Spain sponsored Columbus's voyage."),
                .mc("What was the MAIN reason European countries sponsored exploration in the 1400s–1500s?", choices: ["To spread sports","To find new trade routes to Asia and claim riches","For adventure only","To help Native peoples"], answer: "To find new trade routes to Asia and claim riches", hint: "Shorter trade routes to Asia meant big profits in spices and silk."),
                .mc("The 'Columbian Exchange' refers to…", choices: ["Columbus's travel diary","The transfer of plants, animals, diseases, and ideas between the Americas and Europe/Africa","A trade agreement in 1492","Columbus meeting Native leaders"], answer: "The transfer of plants, animals, diseases, and ideas between the Americas and Europe/Africa", hint: "The Columbian Exchange changed diets and ecosystems on both sides of the Atlantic."),
            ]
        )
    case "colony":
        return LessonContent(
            intro: "The 13 American COLONIES were British settlements in North America from the 1600s–1700s. Colonists came for religious freedom, land, and opportunity — but faced hardships and conflict too. 🏘️",
            exampleQuestion: "How many original colonies became the United States?",
            exampleAnswer: "13 colonies!",
            exampleViz: "13 colonies → 1776 → United States",
            problems: [
                .mc("The Pilgrims came to America in 1620 mainly for…", choices: ["Gold","Religious freedom","Trade routes","Adventure"], answer: "Religious freedom", hint: "The Pilgrims were Separatists seeking freedom to practice their faith."),
                .mc("What was the relationship between Britain and the 13 colonies?", choices: ["Britain was a colony of America","The colonies were governed by Britain but could not vote in Parliament","They were equals","The colonies governed Britain"], answer: "The colonies were governed by Britain but could not vote in Parliament", hint: "This lack of representation — 'taxation without representation' — led to the Revolution."),
                .mc("The first permanent English settlement in America was…", choices: ["Plymouth","Jamestown","Boston","New York"], answer: "Jamestown", hint: "Jamestown, Virginia was founded in 1607 — before the Pilgrims arrived in 1620."),
                .mc("Colonial children typically…", choices: ["Went to school all day like today","Did farm work, chores, and had limited schooling","Had no chores","Worked in factories"], answer: "Did farm work, chores, and had limited schooling", hint: "Colonial life was hard — children helped with farming and household tasks from a young age."),
            ]
        )
    case "rev":
        return LessonContent(
            intro: "The AMERICAN REVOLUTION (1775–1783) was the war when the 13 colonies broke free from British rule. Key ideas: liberty, equality, no taxation without representation. Declaration of Independence: 1776! 🔔",
            exampleQuestion: "What famous document did colonists sign in 1776?",
            exampleAnswer: "The Declaration of Independence — declaring freedom from Britain!",
            exampleViz: "1775: War begins · 1776: Declaration · 1783: Independence won",
            problems: [
                .mc("Who wrote 'Life, Liberty, and the pursuit of Happiness' into the Declaration of Independence?", choices: ["George Washington","John Adams","Thomas Jefferson","Benjamin Franklin"], answer: "Thomas Jefferson", hint: "Thomas Jefferson was the primary author of the Declaration of Independence."),
                .mc("Who commanded the Continental Army during the Revolution?", choices: ["Thomas Jefferson","John Adams","Benjamin Franklin","George Washington"], answer: "George Washington", hint: "Washington led the Continental Army — and later became the first president."),
                .mc("Why did colonists rebel against Britain?", choices: ["Britain attacked first","Colonists were taxed without having a voice in British Parliament","Britain banned all trade","Colonists wanted a king of their own"], answer: "Colonists were taxed without having a voice in British Parliament", hint: "'No taxation without representation!' was a rallying cry."),
                .mc("The Treaty of Paris (1783) officially…", choices: ["Started the Revolutionary War","Ended the war and recognized American independence","Created the Constitution","Established the first Congress"], answer: "Ended the war and recognized American independence", hint: "Britain recognized the USA as an independent nation in the Treaty of Paris."),
            ]
        )
    case "gov":
        return LessonContent(
            intro: "The US government has 3 BRANCHES: LEGISLATIVE (Congress — makes laws), EXECUTIVE (President — carries out laws), JUDICIAL (Supreme Court — interprets laws). This prevents any one person from having too much power! 🏛️",
            exampleQuestion: "Which branch of government makes laws in the USA?",
            exampleAnswer: "The LEGISLATIVE branch — Congress (Senate + House of Representatives).",
            exampleViz: "Legislative 📜 · Executive 🏠 · Judicial ⚖️",
            problems: [
                .mc("The President of the United States is part of which branch?", choices: ["Legislative","Executive","Judicial","Federal"], answer: "Executive", hint: "The President EXECUTES (carries out) the laws."),
                .mc("The Supreme Court is part of which branch?", choices: ["Legislative","Executive","Judicial","Presidential"], answer: "Judicial", hint: "The Supreme Court JUDGES whether laws follow the Constitution."),
                .mc("The system of 'checks and balances' means that…", choices: ["The government checks bank balances","Each branch can limit the power of the others","The President writes all the laws","Congress runs the military"], answer: "Each branch can limit the power of the others", hint: "No single branch becomes too powerful — each 'checks' the others."),
                .mc("How many senators does each US state have?", choices: ["1","2","3","Based on population"], answer: "2", hint: "Every state gets 2 senators regardless of size — 100 senators total."),
            ]
        )
    case "civil":
        return LessonContent(
            intro: "The CIVIL RIGHTS MOVEMENT (1950s–60s) fought for equal rights for African Americans. Leaders like MLK Jr., Rosa Parks, and John Lewis used nonviolent protests to end segregation and win voting rights. 🤝",
            exampleQuestion: "What did the Civil Rights Movement fight for?",
            exampleAnswer: "Equal rights and an end to segregation (separation by race) in the United States.",
            exampleViz: "Rosa Parks · MLK Jr. · March on Washington · Voting Rights Act",
            problems: [
                .mc("Rosa Parks became famous in 1955 for…", choices: ["Running for president","Refusing to give up her bus seat to a white passenger","Writing a famous speech","Leading a march to Washington"], answer: "Refusing to give up her bus seat to a white passenger", hint: "Rosa Parks' brave act sparked the Montgomery Bus Boycott."),
                .mc("Martin Luther King Jr.'s 'I Have a Dream' speech was delivered in…", choices: ["1955","1963","1968","1970"], answer: "1963", hint: "MLK delivered his famous speech at the March on Washington in August 1963."),
                .mc("The Civil Rights Act of 1964 made it illegal to…", choices: ["Vote","Discriminate based on race, color, religion, or national origin","Own land","Attend school"], answer: "Discriminate based on race, color, religion, or national origin", hint: "The Civil Rights Act of 1964 was a landmark law banning discrimination."),
                .mc("What strategy did MLK and other civil rights leaders use?", choices: ["Armed warfare","Nonviolent protest — marches, sit-ins, boycotts","Hiding from the government","Leaving the country"], answer: "Nonviolent protest — marches, sit-ins, boycotts", hint: "Inspired by Gandhi, MLK believed nonviolent resistance was the most powerful tool."),
            ]
        )
    case "tail":
        return LessonContent(
            intro: "Today's stories connect to history! Understanding past events helps us be informed CITIZENS. We read news, understand government, vote, and shape the future. History is STILL being made — by YOU! 📰",
            exampleQuestion: "Why is it important to stay informed about current events?",
            exampleAnswer: "Informed citizens can make better decisions, vote wisely, and help their communities.",
            exampleViz: "Past → Present → Future 📰",
            problems: [
                .mc("A PRIMARY SOURCE is…", choices: ["A library book","An original document or account from the time of an event","A textbook summary","A movie about history"], answer: "An original document or account from the time of an event", hint: "Diaries, letters, photographs, and speeches from the time = primary sources."),
                .mc("Which is an example of a PRIMARY source about the moon landing?", choices: ["A textbook chapter about 1969","Buzz Aldrin's own diary from 1969","A documentary made in 2010","A Wikipedia article"], answer: "Buzz Aldrin's own diary from 1969", hint: "Written by someone WHO WAS THERE at the time = primary source!"),
                .mc("Why do historians look at MULTIPLE sources when studying an event?", choices: ["Because one source is never enough","To get different perspectives and check facts","Reading is more fun with more books","They don't — one source is fine"], answer: "To get different perspectives and check facts", hint: "No single source tells the complete story — multiple sources give a fuller picture."),
                .mc("Being an ACTIVE citizen means…", choices: ["Watching TV all day","Voting, volunteering, staying informed, and participating in community","Only paying taxes","Agreeing with everything the government says"], answer: "Voting, volunteering, staying informed, and participating in community", hint: "Democracy depends on citizens who participate and stay engaged!"),
            ]
        )
    default:
        return LessonContent(
            intro: "Let's explore \(node.label) together! I'll guide you through it step by step.",
            exampleQuestion: "Tap ready when you're set to go!",
            exampleAnswer: "Let's do this!",
            exampleViz: node.emoji,
            problems: [
                .mc("A warm-up question for \(node.label):", choices: ["Option A","Option B","Option C"], answer: "Option A", hint: "Trust your instincts!"),
            ]
        )
    }
}

// MARK: - Chat message model

private enum MessageSource { case nova, student }

private struct ChatMsg: Identifiable {
    let id = UUID()
    let source: MessageSource
    let text: String
    var isHint: Bool = false
    var isStats: Bool = false
    var statsXP: Int = 0
    var statsHearts: Int = 3
    var statsHints: Int = 0
    var answerResult: AnswerResult? = nil
    enum AnswerResult { case correct, incorrect }
}

// MARK: - Input area state

private enum LessonAction { case toExample, toPractice, toDone }

private enum BottomInputKind {
    case action(label: String, kind: LessonAction)
    case mc(choices: [String], problem: LessonProblem, idx: Int)
    case text(problem: LessonProblem, idx: Int)
}

// MARK: - LessonView

struct LessonView: View {
    let node: StarNode
    let constellationName: String        // ← NEW
    let course: String                   // ← NEW
    let blurb: String?                   // ← NEW
    let siblingLabels: [String]          // ← NEW
    let onClose: () -> Void

    @StateObject private var lessonLoader = LessonLoader()  // ← NEW

    @State private var msgs: [ChatMsg] = []
    @State private var isTyping = false
    @State private var streamText: String = ""
    @State private var bottomInput: BottomInputKind? = nil
    @State private var hearts = 3
    @State private var xpGained = 0
    @State private var streak = 0
    @State private var hintsUsed = 0
    @State private var phase: Phase = .intro
    @State private var qIdx = 0
    @State private var hintShown = false
    @State private var questionKey = 0
    @State private var chatBreakInput: String = ""
    @State private var outcomes: [PastProblemOutcome] = []
    @FocusState private var chatBreakFocused: Bool

    @State private var stickerQueue: [StarStickerItem] = []
    @State private var currentStickerToast: StarStickerItem? = nil

    enum Phase { case intro, example, practice, chatBreak, celebrate }

    /// Static lesson for hardcoded stars (used as fallback and for static stars)
    private var lesson: LessonContent { lessonFor(node: node) }

    /// Active lesson — AI-generated if available, otherwise static fallback
    private var activeLesson: LessonContent {     // ← NEW
        lessonLoader.lessonContent ?? lesson
    }

    private var pal: StarPalette {
        let allNeighborIds: [String] = GalaxyData.constellations.flatMap { c in
            c.edges.compactMap { e -> String? in
                if e.a == node.id { return e.b }
                if e.b == node.id { return e.a }
                return nil
            }
        }
        return UserSettings.shared.stage(for: node.id, initiallyLocked: node.initiallyLocked, neighborIds: allNeighborIds).palette
    }

    private var nProbs: Int { activeLesson.problems.count }  // ← CHANGED

    private var progress: Double {
        switch phase {
        case .intro:     return 0.02
        case .example:   return 0.10
        case .practice:  return nProbs > 0 ? 0.12 + Double(qIdx) / Double(nProbs) * 0.85 : 0.12
        case .chatBreak: return nProbs > 0 ? 0.12 + Double(qIdx) / Double(nProbs) * 0.85 : 0.12
        case .celebrate: return 1.0
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0x09041E).ignoresSafeArea()
            stardust.ignoresSafeArea()

            // ← NEW: switch on load state
            switch lessonLoader.state {

            case .idle, .generatingOpening, .generatingProblems:
                lessonLoadingView

            case .ready:
                VStack(spacing: 0) {
                    chatHeader
                    progressStrip
                    chatScroll
                    if phase == .chatBreak {
                        chatBreakInputArea
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let inp = bottomInput {
                        LessonInputArea(
                            inputKind: inp,
                            pal: pal,
                            hintShown: $hintShown,
                            questionKey: questionKey,
                            onAction: handleAction,
                            onAnswer: handleAnswer,
                            onHint: { prob in
                                resetTTS()
                                streamTTS(text: prob.hint, isFinal: true)
                                withAnimation(.easeOut(duration: 0.18)) {
                                    msgs.append(ChatMsg(source: .nova, text: prob.hint, isHint: true))
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: bottomInput != nil)
                .onAppear { if msgs.isEmpty { startIntro() } }  // guard prevents double-fire

            case .failed:
                VStack(spacing: 20) {
                    Spacer()
                    Text("⚠️").font(.system(size: 48))
                    Text("Couldn't generate lesson")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Check your connection and try again.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                    Button("Try Again") {
                        lessonLoader.load(
                            node: node,
                            constellationName: constellationName,
                            course: course,
                            blurb: blurb,
                            siblingLabels: siblingLabels
                        )
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0x3A2A00))
                    .padding(.horizontal, 28).padding(.vertical, 12)
                    .background(Color(hex: 0xFFE066)).clipShape(Capsule())
                    .buttonStyle(.plain)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // ← NEW: .task instead of .onAppear
        .task {
            lessonLoader.load(
                node: node,
                constellationName: constellationName,
                course: course,
                blurb: blurb,
                siblingLabels: siblingLabels
            )
        }
    }

    // MARK: - Loading view (NEW)

    private var lessonLoadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(node.emoji)
                .font(.system(size: 64))
            Text(lessonLoader.progressLabel)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: 0xFFE066))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if !lessonLoader.streamPreview.isEmpty {
                Text(lessonLoader.streamPreview)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(hex: 0x5EE7FF, opacity: 0.55))
                    .lineLimit(3)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dismissesKeyboard()
        .onAppear { startIntro() }
        .overlay {
            if let sticker = currentStickerToast {
                StickerEarnedToast(sticker: sticker) {
                    currentStickerToast = nil
                    if !stickerQueue.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            currentStickerToast = stickerQueue.removeFirst()
                        }
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(Animation.easeInOut(duration: 0.25), value: currentStickerToast != nil)
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Text("←")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.07)))
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

            NovaAvatarView(size: 30, pal: pal)

            VStack(alignment: .leading, spacing: 1) {
                Text("Nova")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 0) {
                    Text("\(node.emoji) \(node.label)")
                        .foregroundColor(.white.opacity(0.5))
                    if phase == .practice || phase == .chatBreak {
                        Text(" · Q\(qIdx+1)/\(nProbs)")
                            .foregroundColor(Color(hex: 0xFFCC50, opacity: 0.6))
                    }
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                if xpGained > 0 {
                    Text("+\(xpGained) XP")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFD044))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: 0xFFD044, opacity: 0.15)))
                        .overlay(Capsule().stroke(Color(hex: 0xFFD044, opacity: 0.3), lineWidth: 1))
                }
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Text("❤️").font(.system(size: 12))
                            .opacity(i < hearts ? 1.0 : 0.18)
                            .animation(.easeOut(duration: 0.3), value: hearts)
                    }
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.top, 50)
        .padding(.bottom, 10)
        .background(
            Color(hex: 0x09041E)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(Rectangle().fill(Color.white.opacity(0.055)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Progress strip

    private var progressStrip: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(LinearGradient(colors: [pal.mid, Color(hex: 0xFFD044)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: g.size.width * max(0, CGFloat(progress)))
                    .shadow(color: pal.glow, radius: 4)
            }
            .animation(.easeInOut(duration: 0.55), value: progress)
        }
        .frame(height: 3)
    }

    // MARK: - Chat scroll

    private var chatScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(msgs) { m in
                        MsgBubble(msg: m, pal: pal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    if isTyping {
                        TypingBubble(pal: pal).id("typing")
                    }
                    Color.clear.frame(height: 6).id("__end")
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.visible)
            .onAppear { proxy.scrollTo("__end", anchor: .bottom) }
            .onChange(of: msgs.count) { withAnimation { proxy.scrollTo("__end", anchor: .bottom) } }
            .onChange(of: isTyping)   { withAnimation { proxy.scrollTo("__end", anchor: .bottom) } }
            .onChange(of: streamText) { withAnimation { proxy.scrollTo("__end", anchor: .bottom) } }
        }
    }

    // MARK: - Stardust bg

    private var stardust: some View {
        Canvas { ctx, sz in
            for (px, py, pr): (Double, Double, Double) in [
                (0.12, 0.18, 0.7), (0.88, 0.08, 0.5),
                (0.42, 0.88, 0.5), (0.76, 0.72, 0.45),
                (0.22, 0.55, 0.4), (0.60, 0.35, 0.35),
            ] {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px * sz.width - pr, y: py * sz.height - pr, width: pr * 2, height: pr * 2)),
                    with: .color(.white.opacity(0.55))
                )
            }
        }
        .opacity(0.5)
        .allowsHitTesting(false)
    }

    // MARK: - Nova message queue

    private func sendNova(_ texts: [String], then: (() -> Void)? = nil) {
        bottomInput = nil
        resetTTS()
        let fullSpeech = texts.joined(separator: " ").replacingOccurrences(of: " · ", with: ". ")
        streamTTS(text: fullSpeech, isFinal: true)

        var delay: Double = 0
        for text in texts {
            let dur = min(0.35 + Double(text.count) * 0.018, 1.1)
            let d0 = delay
            DispatchQueue.main.asyncAfter(deadline: .now() + d0) {
                withAnimation(.easeOut(duration: 0.18)) { isTyping = true }
            }
            delay += dur
            let d1 = delay; let captured = text
            DispatchQueue.main.asyncAfter(deadline: .now() + d1) {
                withAnimation(.easeOut(duration: 0.15)) {
                    isTyping = false
                    msgs.append(ChatMsg(source: .nova, text: captured))
                }
            }
            delay += 0.12
        }
        if let cb = then {
            let final = delay + 0.08
            DispatchQueue.main.asyncAfter(deadline: .now() + final) {
                withAnimation { cb() }
            }
        }
    }

    private func sendNovaAI(userQuery: String, then: (() -> Void)? = nil) {
        bottomInput = nil
        withAnimation(.easeOut(duration: 0.18)) { isTyping = true }

        let context = PipelineContext(
            activeConstellationID: GalaxyData.nodesById[node.id]?.constellationId,
            activeStarID: node.id,
            studentName: "Explorer",
            history: msgs.compactMap { m in
                guard !m.isHint && !m.isStats else { return nil }
                return ChatMessage(
                    role: m.source == .student ? .user : .assistant,
                    content: m.text
                )
            }
        )

        RAGPipeline.run(
            userQuery: userQuery,
            context: context,
            onDownload: { _ in },
            onStream: { currentText in
                DispatchQueue.main.async { self.streamText = currentText }
            },
            onComplete: { result in
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isTyping = false
                        msgs.append(ChatMsg(source: .nova, text: responseText))
                        self.streamText = ""
                    }
                    then?()
                }
            }
        )
    }

    // MARK: - Lesson flow

    private func startIntro() {
        // ← CHANGED: read from lessonLoader
        let intro = lessonLoader.lessonContent?.intro ?? ""
        sendNova([
            "Hey, space explorer! 🚀",
            "Today we're tackling \(node.label).",
            activeLesson.intro,   // ← CHANGED
        ]) {
            bottomInput = .action(label: "Let's go! 🚀", kind: .toExample)
        }
    }

    private func startExample() {
        phase = .example
        // ← CHANGED: read from lessonLoader
        let exQ = lessonLoader.lessonContent?.exampleQuestion ?? ""
        let exA = lessonLoader.lessonContent?.exampleAnswer ?? ""
        sendNova([
            "Let me show you one first. 👀",
            activeLesson.exampleQuestion,   // ← CHANGED
            "The answer: \(activeLesson.exampleAnswer)",   // ← CHANGED
            "Got it? Now let's see what you can do! 💪",
        ]) {
            bottomInput = .action(label: "Try me! 💪", kind: .toPractice)
        }
    }

    private func startPractice() {
        phase = .practice
        askQ(0)
    }

    private func askQ(_ idx: Int) {
        qIdx = idx
        hintShown = false
        questionKey += 1

        let problems = activeLesson.problems   // ← CHANGED
        guard idx < problems.count else { celebrate(); return }
        var p = problems[idx]

        if p.kind == .pizza {
            let choices = (1...max(1, p.slices)).map { "\($0)/\(p.slices)" }
            let answer = "\(p.target)/\(p.slices)"
            let prompt = p.prompt
                .replacingOccurrences(of: "Tap to color in", with: "How many slices for")
                .replacingOccurrences(of: "Tap to show", with: "How many slices for")
            p = LessonProblem.mc(prompt, choices: choices, answer: answer, hint: p.hint)
        }

        sendNova(["Q\(idx+1)/\(nProbs) · \(p.prompt)"]) {
            switch p.kind {
            case .multipleChoice:
                bottomInput = .mc(choices: p.choices, problem: p, idx: idx)
            case .input, .pizza:
                bottomInput = .text(problem: p, idx: idx)
            }
        }
    }

    private func handleAction(_ kind: LessonAction) {
        switch kind {
        case .toExample:  startExample()
        case .toPractice: startPractice()
        case .toDone:     onClose()
        }
    }

    private func handleAnswer(val: String, problem: LessonProblem, idx: Int, usedHint: Bool) {
        let correct = val.trimmingCharacters(in: .whitespaces).lowercased()
                      == problem.answer.trimmingCharacters(in: .whitespaces).lowercased()

        withAnimation(.easeOut(duration: 0.18)) {
            msgs.append(ChatMsg(
                source: .student,
                text: val,
                answerResult: correct ? .correct : .incorrect
            ))
        }
        bottomInput = nil

        outcomes.append(PastProblemOutcome(
            prompt: problem.prompt,
            correctAnswer: problem.answer,
            studentAnswer: val,
            correct: correct,
            attempts: 1,
            hintUsed: usedHint
        ))

        if correct {
            streak += 1
            xpGained += (usedHint ? 8 : 15) + (streak >= 2 ? 5 : 0)
        } else {
            streak = 0
            hearts = max(0, hearts - 1)
        }
        if usedHint { hintsUsed += 1 }

        let next = idx + 1
        let done = next >= nProbs

        let feedbackQuery = correct
            ? "The student answered '\(val)' which is correct for the question: '\(problem.prompt)'. Give a short encouraging response\(streak >= 3 ? " and mention their \(streak)-answer streak" : "")."
            : "The student answered '\(val)' but the correct answer is '\(problem.answer)' for the question: '\(problem.prompt)'. Gently explain why and offer to answer any questions they have."

        sendNovaAI(userQuery: feedbackQuery) {
            if done { self.celebrate() } else {
                self.phase = .chatBreak
                self.qIdx = next
            }
        }
    }

    private func celebrate() {
        phase = .celebrate
        let capXP = xpGained; let capH = hearts; let capHints = hintsUsed
        let capOutcomes = outcomes
        let correctCount = capOutcomes.filter { $0.correct }.count
        let constellationId = GalaxyData.nodesById[node.id]?.constellationId

        Task {
            await MemoryStore.shared.recordLesson(
                node: node,
                constellationName: GalaxyData.nodesById[node.id]?.constellationName,
                outcomes: capOutcomes,
                xpGained: capXP,
                heartsLeft: capH,
                hintsUsed: capHints
            )
        }
        UserSettings.shared.recordStudySession(
            xpEarned: capXP,
            nodeId: node.id,
            correctCount: correctCount,
            totalCount: capOutcomes.count,
            hintsUsed: capHints,
            constellationId: constellationId
        )

        NotificationCenter.default.post(
            name: .lessonCompleted,
            object: nil,
            userInfo: ["nodeId": node.id, "xp": capXP]
        )

        let newIds = UserSettings.shared.recentlyUnlocked
        if !newIds.isEmpty {
            let allStickers = StarStickerData.items(
                unlocked: UserSettings.shared.unlockedStickers,
                dates: UserSettings.shared.stickerEarnedDates
            )
            let newStickers = newIds.compactMap { id in allStickers.first { $0.id == id } }
            if let first = newStickers.first {
                NotificationManager.shared.scheduleStickerEarnedNotification(
                    name: UserSettings.shared.explorerName,
                    stickerName: first.label,
                    emoji: first.emoji
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    stickerQueue = Array(newStickers.dropFirst())
                    currentStickerToast = first
                }
            }
        }

        sendNova([
            "🎉 Lesson complete, superstar!",
            "You answered all \(nProbs) questions. Here's how you did:",
        ]) {
            var sm = ChatMsg(source: .nova, text: "")
            sm.isStats = true
            sm.statsXP = capXP
            sm.statsHearts = capH
            sm.statsHints = capHints
            withAnimation(.easeOut(duration: 0.2)) { self.msgs.append(sm) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { self.bottomInput = .action(label: "Back to galaxy 🌌", kind: .toDone) }
            }
        }
    }

    // MARK: - Chat break

    private var chatBreakInputArea: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("", text: $chatBreakInput,
                              prompt: Text("Ask Nova more about this…")
                                  .foregroundColor(.white.opacity(0.4)))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1.5))
                        .focused($chatBreakFocused)
                        .onSubmit { sendChatBreakMessage() }

                    Button(action: sendChatBreakMessage) {
                        Text("→")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(chatBreakInput.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? .white.opacity(0.25) : Color(hex: 0x1A0B40))
                            .frame(width: 48, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(chatBreakInput.trimmingCharacters(in: .whitespaces).isEmpty
                                          ? AnyShapeStyle(Color.white.opacity(0.07))
                                          : AnyShapeStyle(LinearGradient(
                                                colors: [pal.mid, pal.halo],
                                                startPoint: .topLeading, endPoint: .bottomTrailing)))
                            )
                            .shadow(color: chatBreakInput.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? .clear : pal.glow.opacity(0.6), radius: 10)
                    }
                    .buttonStyle(.plain)
                    .disabled(chatBreakInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Button(action: resumeAfterChatBreak) {
                    Text(qIdx >= nProbs ? "🎉 Finish lesson!" : "Next question →")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0x1A0B40))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(LinearGradient(colors: [pal.mid, pal.halo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: pal.glow.opacity(0.5), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 28, trailing: 14))
        }
        .background(Color(hex: 0x09041E))
    }

    private func sendChatBreakMessage() {
        let q = chatBreakInput.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        chatBreakInput = ""
        chatBreakFocused = false
        withAnimation(.easeOut(duration: 0.18)) {
            msgs.append(ChatMsg(source: .student, text: q))
        }
        sendNovaAI(userQuery: q)
    }

    private func resumeAfterChatBreak() {
        phase = .practice
        if qIdx >= nProbs { celebrate() } else { askQ(qIdx) }
    }
}

// MARK: - Copy lines

private func randomCheer() -> String {
    ["You got it! ⭐","Stellar! 🚀","Nailed it! ✨","Bingo! 🎯","That's the one! 💫","Cosmic! Keep going!","Wow, nice work! 🌟"].randomElement() ?? "Nice!"
}
private func randomEncourage() -> String {
    ["No worries — let's keep going!","Every explorer gets it on the next try.","Mistakes are how we grow 🌱","Onwards and upwards!"].randomElement() ?? "Keep going!"
}

// MARK: - Nova avatar

struct NovaAvatarView: View {
    let size: CGFloat
    let pal: StarPalette

    var body: some View {
        Image("Nova Image")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: pal.glow, radius: size * 0.3)
    }
}

// MARK: - Markdown-aware text renderer
//
// Uses AttributedString(markdown:) so Nova's messages can contain:
//   **bold**  *italic*  `code`  ~~strikethrough~~  [link](url)
// Falls back to plain Text if the string fails to parse (shouldn't happen in practice).
// .inlineOnlyPreservingWhitespace keeps newlines but skips block-level syntax
// (headers, HR, fenced code blocks) which would look wrong in a chat bubble.

private struct MarkdownText: View {
    let text: String
    var fontSize: CGFloat = 14.5
    var weight: Font.Weight = .regular
    var color: Color = Color(hex: 0xE8D8FF)
    var lineSpacing: CGFloat = 2

    private var attributed: AttributedString {
        let opts = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: text, options: opts))
            ?? AttributedString(text)
    }

    var body: some View {
        Text(attributed)
            .font(.system(size: fontSize, weight: weight, design: .rounded))
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
    }
}

// MARK: - Chat bubble

private struct MsgBubble: View {
    let msg: ChatMsg
    let pal: StarPalette

    var body: some View {
        if msg.isStats {
            statsBubble
        } else if msg.source == .nova {
            novaBubble
        } else {
            studentBubble
        }
    }

    private var novaBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            MarkdownText(
                text: msg.text,
                color: msg.isHint ? Color(hex: 0x5EE7FF) : Color(hex: 0xE8D8FF)
            )
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(msg.isHint ? Color(hex: 0x5EE7FF, opacity: 0.1) : Color(hex: 0x201048, opacity: 0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(msg.isHint ? Color(hex: 0x5EE7FF, opacity: 0.3) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
            Spacer(minLength: 44)
        }
    }

    private var studentBubble: some View {
        HStack {
            Spacer(minLength: 44)
            Text(msg.text)
                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(2)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            msg.answerResult == .correct
                                ? AnyShapeStyle(LinearGradient(
                                    colors:[Color(hex: 0x34C759), Color(hex: 0x30B354)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                : msg.answerResult == .incorrect
                                ? AnyShapeStyle(LinearGradient(
                                    colors:[Color(hex: 0xFF3B30), Color(hex: 0xD93025)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors:[Color(hex: 0xFF8A4C), Color(hex: 0xFFCC44)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                )
                .shadow(color: msg.answerResult == .correct
                            ? Color(hex: 0x34C759, opacity: 0.4)
                            : msg.answerResult == .incorrect
                            ? Color(hex: 0xFF3B30, opacity: 0.4)
                            : Color(hex: 0xFF8A4C, opacity: 0.3),
                        radius: 8, x: 0, y: 2)
        }
    }

    private var statsBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            LazyVGrid(columns:[GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                statTile("✨", label: "XP earned",   val: "+\(msg.statsXP)",      c: Color(hex: 0xFFE066))
                statTile("❤️", label: "Hearts left", val: "\(msg.statsHearts)/3", c: Color(hex: 0xFF8AD8))
                statTile("💡", label: "Hints used",  val: "\(msg.statsHints)",    c: Color(hex: 0x5EE7FF))
                statTile("🔥", label: "Streak",      val: "+1 day",               c: Color(hex: 0xFF8A4C))
            }
            .frame(width: 240)
            Spacer(minLength: 0)
        }
    }

    private func statTile(_ icon: String, label: String, val: String, c: Color) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 16))
            Text(val)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(c)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(0.3)
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8).padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Markdown bubble renderer

private struct MarkdownBubbleText: View {
    let text: String
    let baseColor: Color
    let fontSize: CGFloat

    init(_ text: String, color: Color, fontSize: CGFloat = 14.5) {
        self.text = text
        self.baseColor = color
        self.fontSize = fontSize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(parsedLines.enumerated()), id: \.offset) { _, line in
                renderedLine(line)
            }
        }
    }

    private enum LineKind { case heading(Int), bullet(Int), numbered(Int), empty, body }
    private struct ParsedLine { let kind: LineKind; let content: String }

    private var parsedLines: [ParsedLine] {
        text.components(separatedBy: "\n").map { line in
            let s = line.trimmingCharacters(in: .whitespaces)
            guard !s.isEmpty else { return ParsedLine(kind: .empty, content: "") }
            if s.hasPrefix("### ") { return ParsedLine(kind: .heading(3), content: String(s.dropFirst(4))) }
            if s.hasPrefix("## ")  { return ParsedLine(kind: .heading(2), content: String(s.dropFirst(3))) }
            if s.hasPrefix("# ")   { return ParsedLine(kind: .heading(1), content: String(s.dropFirst(2))) }
            let indent = line.prefix(while: { $0 == " " }).count / 2
            if s.hasPrefix("- ") || s.hasPrefix("* ") || s.hasPrefix("• ") {
                return ParsedLine(kind: .bullet(indent), content: String(s.dropFirst(2)))
            }
            let parts = s.split(separator: " ", maxSplits: 1)
            if parts.count == 2, let marker = parts.first,
               (marker.hasSuffix(".") || marker.hasSuffix(")")),
               Int(String(marker.dropLast())) != nil {
                return ParsedLine(kind: .numbered(Int(String(marker.dropLast())) ?? 0), content: String(parts[1]))
            }
            return ParsedLine(kind: .body, content: s)
        }
    }

    @ViewBuilder
    private func renderedLine(_ line: ParsedLine) -> some View {
        switch line.kind {
        case .empty:
            Color.clear.frame(height: 2)
        case .heading(let level):
            let sz: CGFloat = level == 1 ? fontSize + 3 : level == 2 ? fontSize + 1.5 : fontSize
            inlineText(line.content)
                .font(.system(size: sz, weight: .bold, design: .rounded))
                .foregroundColor(baseColor)
                .fixedSize(horizontal: false, vertical: true)
        case .bullet(let indent):
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("•")
                    .font(.system(size: fontSize, design: .rounded))
                    .foregroundColor(baseColor.opacity(0.7))
                inlineText(line.content)
                    .font(.system(size: fontSize, weight: .regular, design: .rounded))
                    .foregroundColor(baseColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(indent) * 10)
        case .numbered(let n):
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(n).")
                    .font(.system(size: fontSize, design: .rounded))
                    .foregroundColor(baseColor.opacity(0.7))
                    .frame(minWidth: 18, alignment: .trailing)
                inlineText(line.content)
                    .font(.system(size: fontSize, weight: .regular, design: .rounded))
                    .foregroundColor(baseColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .body:
            inlineText(line.content)
                .font(.system(size: fontSize, weight: .regular, design: .rounded))
                .foregroundColor(baseColor)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func inlineText(_ raw: String) -> Text {
        if let attr = try? AttributedString(
            markdown: raw,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attr)
        }
        return Text(raw)
    }
}

// MARK: - Typing indicator

private struct TypingBubble: View {
    let pal: StarPalette
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            BouncingDots()
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0x201048, opacity: 0.9)))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
    }
}

private struct BouncingDots: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate * 4.5
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 6, height: 6)
                        .offset(y: CGFloat(sin(t + Double(i) * 0.7) * -3.5))
                }
            }
        }
    }
}

// MARK: - Bottom input area

private struct LessonInputArea: View {
    let inputKind: BottomInputKind
    let pal: StarPalette
    @Binding var hintShown: Bool
    let questionKey: Int
    let onAction: (LessonAction) -> Void
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            Group {
                switch inputKind {
                case .action(let label, let kind):
                    actionView(label: label, kind: kind)
                case .mc(let choices, let problem, let idx):
                    MCChoicesView(choices: choices, problem: problem, idx: idx, pal: pal, hintShown: $hintShown, onAnswer: onAnswer, onHint: onHint)
                        .id(questionKey)
                case .text(let problem, let idx):
                    TextInputView(problem: problem, idx: idx, pal: pal, hintShown: $hintShown, onAnswer: onAnswer, onHint: onHint)
                        .id(questionKey)
                }
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 28, trailing: 14))
        }
        .background(Color(hex: 0x09041E))
    }

    private func actionView(label: String, kind: LessonAction) -> some View {
        Button(action: { onAction(kind) }) {
            Text(label)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x1A0B40))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [pal.mid, pal.halo], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: pal.glow, radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MC choices

private struct MCChoicesView: View {
    let choices: [String]
    let problem: LessonProblem
    let idx: Int
    let pal: StarPalette
    @Binding var hintShown: Bool
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem) -> Void
    @State private var tapped: String? = nil

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(choices.enumerated()), id: \.offset) { i, ch in
                let isTapped = tapped == ch
                Button(action: {
                    guard tapped == nil else { return }
                    tapped = ch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                        onAnswer(ch, problem, idx, hintShown)
                    }
                }) {
                    HStack(spacing: 10) {
                        Text(String(UnicodeScalar(65 + i)!))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(isTapped ? .white : Color(hex: 0xC8AAF0, opacity: 0.8))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(isTapped ? Color.white.opacity(0.25) : Color.white.opacity(0.08)))
                        Text(ch)
                            .font(.system(size: 14, weight: isTapped ? .bold : .medium, design: .rounded))
                            .foregroundColor(isTapped ? .white : Color(hex: 0xE6D2FF, opacity: 0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isTapped
                                  ? AnyShapeStyle(LinearGradient(colors: [pal.mid.opacity(0.8), pal.halo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color.white.opacity(0.055)))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isTapped ? pal.mid : Color.white.opacity(0.12), lineWidth: 1.5))
                    .shadow(color: isTapped ? pal.glow.opacity(0.5) : .clear, radius: 8)
                    .animation(.easeOut(duration: 0.15), value: isTapped)
                }
                .buttonStyle(.plain)
                .disabled(tapped != nil)
            }
            HintButton(problem: problem, hintShown: $hintShown, onHint: onHint)
        }
    }
}

// MARK: - Text input

private struct TextInputView: View {
    let problem: LessonProblem
    let idx: Int
    let pal: StarPalette
    @Binding var hintShown: Bool
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem) -> Void
    @State private var textVal = ""

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("", text: $textVal, prompt: Text("Your answer…").foregroundColor(.white.opacity(0.4)))
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1.5))
                    .onSubmit { submit() }
                Button(action: submit) {
                    Text("→")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(textVal.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.25) : Color(hex: 0x1A0B40))
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(textVal.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? AnyShapeStyle(Color.white.opacity(0.07))
                                      : AnyShapeStyle(LinearGradient(colors: [pal.mid, pal.halo], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        )
                        .shadow(color: textVal.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : pal.glow.opacity(0.6), radius: 10)
                }
                .buttonStyle(.plain)
                .disabled(textVal.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            HintButton(problem: problem, hintShown: $hintShown, onHint: onHint)
        }
    }

    private func submit() {
        let v = textVal.trimmingCharacters(in: .whitespaces)
        guard !v.isEmpty else { return }
        onAnswer(v, problem, idx, hintShown)
    }
}

// MARK: - Hint button

private struct HintButton: View {
    let problem: LessonProblem
    @Binding var hintShown: Bool
    let onHint: (LessonProblem) -> Void

    var body: some View {
        if !hintShown && !problem.hint.isEmpty {
            Button(action: { hintShown = true; onHint(problem) }) {
                HStack(spacing: 6) {
                    Text("💡 Show hint")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0x5EE7FF))
                    Text("(−7 XP)")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: 0x5EE7FF, opacity: 0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(hex: 0x5EE7FF, opacity: 0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }
            .buttonStyle(.plain)
        }
    }
}
