// const std = @import("std");
// const testing = std.testing;

// fn LinkedList(comptime T: type) type {
//     return struct {
//         const Self = @This();

//         pub const Node = struct {
//             prev: ?*Node = null,
//             next: ?*Node = null,
//             data: T,
//         };

//         first: ?*Node = null,
//         last: ?*Node = null,
//         len: usize = 0,

//         pub fn push(self: *Self, new_node: *Node) void {
//             self.len += 1;
//             if (self.last) |last| {
//                 last.next = new_node;
//                 new_node.prev = self.last;
//                 self.last = new_node;
//             } else {
//                 self.first = new_node;
//                 self.last = new_node;
//             }
//         }

//         pub fn pop(self: *Self) ?*Node {
//             if (self.len == 0) {
//                 return null;
//             }
//             if (self.len == 1) {
//                 self.len = 0;
//                 self.first = null;
//                 defer self.last = null;
//                 return self.last;
//             }
//             self.len -= 1;
//             const popped = self.last;
//             self.last = popped.?.prev;
//             self.last.?.next = null;
//             popped.?.prev = null;
//             return popped;
//         }

//         pub fn shift(self: *Self) ?*Node {
//             if (self.len == 0) {
//                 return null;
//             }
//             if (self.len == 1) {
//                 self.len = 0;
//                 self.first = null;
//                 defer self.last = null;
//                 return self.last;
//             }
//             self.len -= 1;
//             const shifted = self.first;
//             self.first = shifted.?.next;
//             self.first.?.prev = null;
//             shifted.?.next = null;
//             return shifted;
//         }

//         // add at start
//         pub fn unshift(self: *Self, new_node: *Node) void {
//             if (self.len == 0) {
//                 self.first = new_node;
//                 self.last = new_node;
//                 self.len = 1;
//                 return;
//             }
//             self.first.?.prev = new_node;
//             new_node.next = self.first;
//             self.first = new_node;
//             self.len += 1;
//         }

//         pub fn delete(self: *Self, node: *Node) void {
//             if (self.len == 0) {
//                 return;
//             }
//             if (self.len == 1) {
//                 if (self.first.? == node) {
//                     self.first = null;
//                     self.last = null;
//                     self.len = 0;
//                 }
//             }
//             var curr = self.first;
//             while (curr) |current_node| {
//                 if (current_node.data == node.data) {
//                     if (current_node.next) |next| {
//                         next.prev = current_node.prev;
//                         if (current_node == self.first) {
//                             self.first = next;
//                         }
//                     }
//                     if (current_node.prev) |prev| {
//                         prev.next = current_node.next;
//                         if (current_node == self.last) {
//                             self.last = prev;
//                         }
//                     }
//                     self.len -= 1;
//                     break;
//                 }
//                 curr = current_node.next;
//             }
//         }
//     };
// }

// const List = LinkedList(usize);
// test "pop gets element from the list" {
//     var list = List{};
//     var a = List.Node{ .data = 7 };
//     list.push(&a);
//     try testing.expectEqual(@as(usize, 7), list.pop().?.data);
// }
// test "push/pop respectively add/remove at the end of the list" {
//     var list = List{};
//     var a = List.Node{ .data = 11 };
//     var b = List.Node{ .data = 13 };
//     list.push(&a);
//     list.push(&b);
//     try testing.expectEqual(@as(usize, 13), list.pop().?.data);
//     try testing.expectEqual(@as(usize, 11), list.pop().?.data);
// }
// test "shift gets an element from the list" {
//     var list = List{};
//     var a = List.Node{ .data = 17 };
//     list.push(&a);
//     try testing.expectEqual(@as(usize, 17), list.shift().?.data);
// }
// test "shift gets first element from the list" {
//     var list = List{};
//     var a = List.Node{ .data = 23 };
//     var b = List.Node{ .data = 5 };
//     list.push(&a);
//     list.push(&b);
//     try testing.expectEqual(@as(usize, 23), list.shift().?.data);
//     try testing.expectEqual(@as(usize, 5), list.shift().?.data);
// }
// test "unshift adds element at start of the list" {
//     var list = List{};
//     var a = List.Node{ .data = 23 };
//     var b = List.Node{ .data = 5 };
//     list.unshift(&a);
//     list.unshift(&b);
//     try testing.expectEqual(@as(usize, 5), list.shift().?.data);
//     try testing.expectEqual(@as(usize, 23), list.shift().?.data);
// }
// test "pop, push, shift, and unshift can be used in any order" {
//     var list = List{};
//     var a = List.Node{ .data = 1 };
//     var b = List.Node{ .data = 2 };
//     var c = List.Node{ .data = 3 };
//     var d = List.Node{ .data = 4 };
//     var e = List.Node{ .data = 5 };
//     list.push(&a);
//     list.push(&b);
//     try testing.expectEqual(@as(usize, 2), list.pop().?.data);
//     list.push(&c);
//     try testing.expectEqual(@as(usize, 1), list.shift().?.data);
//     list.unshift(&d);
//     list.push(&e);
//     try testing.expectEqual(@as(usize, 4), list.shift().?.data);
//     try testing.expectEqual(@as(usize, 5), list.pop().?.data);
//     try testing.expectEqual(@as(usize, 3), list.shift().?.data);
// }
// test "count an empty list" {
//     const list = List{};
//     try testing.expectEqual(@as(usize, 0), list.len);
// }
// test "count a list with items" {
//     var list = List{};
//     var a = List.Node{ .data = 37 };
//     var b = List.Node{ .data = 1 };
//     list.push(&a);
//     list.push(&b);
//     try testing.expectEqual(@as(usize, 2), list.len);
// }
// test "count is correct after mutation" {
//     var list = List{};
//     var a = List.Node{ .data = 31 };
//     var b = List.Node{ .data = 43 };
//     list.push(&a);
//     try testing.expectEqual(@as(usize, 1), list.len);
//     list.unshift(&b);
//     try testing.expectEqual(@as(usize, 2), list.len);
//     _ = list.shift();
//     try testing.expectEqual(@as(usize, 1), list.len);
//     _ = list.pop();
//     try testing.expectEqual(@as(usize, 0), list.len);
// }
// test "popping to empty doesn't break the list" {
//     var list = List{};
//     var a = List.Node{ .data = 41 };
//     var b = List.Node{ .data = 59 };
//     var c = List.Node{ .data = 47 };
//     list.push(&a);
//     list.push(&b);
//     _ = list.pop();
//     _ = list.pop();
//     list.push(&c);
//     try testing.expectEqual(@as(usize, 1), list.len);
//     try testing.expectEqual(@as(usize, 47), list.pop().?.data);
// }
// test "shifting to empty doesn't break the list" {
//     var list = List{};
//     var a = List.Node{ .data = 41 };
//     var b = List.Node{ .data = 59 };
//     var c = List.Node{ .data = 47 };
//     list.push(&a);
//     list.push(&b);
//     _ = list.shift();
//     _ = list.shift();
//     list.push(&c);
//     try testing.expectEqual(@as(usize, 1), list.len);
//     try testing.expectEqual(@as(usize, 47), list.shift().?.data);
// }
// test "deletes the only element" {
//     var list = List{};
//     var a = List.Node{ .data = 61 };
//     list.push(&a);
//     list.delete(&a);
//     try testing.expectEqual(@as(usize, 0), list.len);
// }
// test "deletes the element with the specified value from the list" {
//     var list = List{};
//     var a = List.Node{ .data = 71 };
//     var b = List.Node{ .data = 83 };
//     var c = List.Node{ .data = 79 };
//     list.push(&a);
//     list.push(&b);
//     list.push(&c);
//     list.delete(&b);
//     try testing.expectEqual(@as(usize, 2), list.len);
//     try testing.expectEqual(@as(usize, 79), list.pop().?.data);
//     try testing.expectEqual(@as(usize, 71), list.shift().?.data);
// }
// test "deletes the element with the specified value from the list, re-assigns tail" {
//     var list = List{};
//     var a = List.Node{ .data = 71 };
//     var b = List.Node{ .data = 83 };
//     var c = List.Node{ .data = 79 };
//     list.push(&a);
//     list.push(&b);
//     list.push(&c);
//     list.delete(&b);
//     try testing.expectEqual(@as(usize, 2), list.len);
//     try testing.expectEqual(@as(usize, 79), list.pop().?.data);
//     try testing.expectEqual(@as(usize, 71), list.pop().?.data);
// }
// test "deletes the element with the specified value from the list, re-assigns head" {
//     var list = List{};
//     var a = List.Node{ .data = 71 };
//     var b = List.Node{ .data = 83 };
//     var c = List.Node{ .data = 79 };
//     list.push(&a);
//     list.push(&b);
//     list.push(&c);
//     list.delete(&b);
//     try testing.expectEqual(@as(usize, 2), list.len);
//     try testing.expectEqual(@as(usize, 71), list.shift().?.data);
//     try testing.expectEqual(@as(usize, 79), list.shift().?.data);
// }
// test "deletes the first of two elements" {
//     var list = List{};
//     var a = List.Node{ .data = 97 };
//     var b = List.Node{ .data = 101 };
//     list.push(&a);
//     list.push(&b);
//     list.delete(&a);
//     try testing.expectEqual(@as(usize, 1), list.len);
//     try testing.expectEqual(@as(usize, 101), list.pop().?.data);
// }
// test "deletes the second of two elements" {
//     var list = List{};
//     var a = List.Node{ .data = 97 };
//     var b = List.Node{ .data = 101 };
//     list.push(&a);
//     list.push(&b);
//     list.delete(&b);
//     try testing.expectEqual(@as(usize, 1), list.len);
//     try testing.expectEqual(@as(usize, 97), list.pop().?.data);
// }
// test "delete does not modify the list if the element is not found" {
//     var list = List{};
//     var a = List.Node{ .data = 89 };
//     var b = List.Node{ .data = 103 };
//     list.push(&a);
//     list.delete(&b);
//     try testing.expectEqual(@as(usize, 1), list.len);
// }
// test "deletes only the first occurrence" {
//     var list = List{};
//     var a = List.Node{ .data = 73 };
//     var b = List.Node{ .data = 9 };
//     var c = List.Node{ .data = 9 };
//     var d = List.Node{ .data = 107 };
//     list.push(&a);
//     list.push(&b);
//     list.push(&c);
//     list.push(&d);
//     list.delete(&b);
//     try testing.expectEqual(@as(usize, 3), list.len);
//     try testing.expectEqual(@as(usize, 107), list.pop().?.data);
//     try testing.expectEqual(@as(usize, 9), list.pop().?.data);
//     try testing.expectEqual(@as(usize, 73), list.pop().?.data);
// }

const std = @import("std");
const mem = std.mem;
const toLower = std.ascii.toLower;

/// Returns the set of strings in `candidates` that are anagrams of `word`.
/// Caller owns the returned memory.
pub fn detectAnagrams(
    allocator: mem.Allocator,
    word: []const u8,
    candidates: []const []const u8,
) !std.BufSet {
    var word_char_count = std.AutoHashMap(u8, usize).init(allocator);
    defer word_char_count.deinit();

    for (word) |letter| {
        const entry = try word_char_count.getOrPut(toLower(letter));
        if (!entry.found_existing) {
            entry.value_ptr.* = 0;
        }
        entry.value_ptr.* += 1;
    }

    var anagrams = std.BufSet.init(allocator);
    for (candidates) |candidate| {
        if (std.ascii.eqlIgnoreCase(word, candidate)) {
            continue;
        }

        var candidate_char_count = std.AutoHashMap(u8, usize).init(allocator);
        defer candidate_char_count.deinit();

        for (candidate) |letter| {
            const entry = try candidate_char_count.getOrPut(toLower(letter));
            if (!entry.found_existing) {
                entry.value_ptr.* = 0;
            }
            entry.value_ptr.* += 1;
        }

        if (are_hash_maps_equal(&word_char_count, &candidate_char_count)) {
            try anagrams.insert(candidate);
        }
    }
    return anagrams;
}

fn are_hash_maps_equal(
    map_1: *std.AutoHashMap(u8, usize),
    map_2: *std.AutoHashMap(u8, usize),
) bool {
    if (map_1.count() != map_2.count()) {
        return false;
    }

    var entries = map_1.iterator();
    while (entries.next()) |entry| {
        const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;

        if (map_2.get(key)) |map_2_value| {
            if (map_2_value != value) {
                return false;
            }
        } else {
            return false;
        }
    }
    return true;
}

const testing = std.testing;

fn testAnagrams(
    expected: []const []const u8,
    word: []const u8,
    candidates: []const []const u8,
) !void {
    var actual = try detectAnagrams(testing.allocator, word, candidates);
    defer actual.deinit();
    try testing.expectEqual(expected.len, actual.count());
    for (expected) |e| {
        try testing.expect(actual.contains(e));
    }
}
test "no matches" {
    const expected = [_][]const u8{};
    const word = "diaper";
    const candidates = [_][]const u8{ "hello", "world", "zombies", "pants" };
    try testAnagrams(&expected, word, &candidates);
}
test "detects two anagrams" {
    const expected = [_][]const u8{ "lemons", "melons" };
    const word = "solemn";
    const candidates = [_][]const u8{ "lemons", "cherry", "melons" };
    try testAnagrams(&expected, word, &candidates);
}
test "does not detect anagram subsets" {
    const expected = [_][]const u8{};
    const word = "good";
    const candidates = [_][]const u8{ "dog", "goody" };
    try testAnagrams(&expected, word, &candidates);
}
test "detects anagram" {
    const expected = [_][]const u8{"inlets"};
    const word = "listen";
    const candidates = [_][]const u8{ "enlists", "google", "inlets", "banana" };
    try testAnagrams(&expected, word, &candidates);
}
test "detects three anagrams" {
    const expected = [_][]const u8{ "gallery", "regally", "largely" };
    const word = "allergy";
    const candidates = [_][]const u8{ "gallery", "ballerina", "regally", "clergy", "largely", "leading" };
    try testAnagrams(&expected, word, &candidates);
}
test "detects multiple anagrams with different case" {
    const expected = [_][]const u8{ "Eons", "ONES" };
    const word = "nose";
    const candidates = [_][]const u8{ "Eons", "ONES" };
    try testAnagrams(&expected, word, &candidates);
}
test "does not detect non-anagrams with identical checksum" {
    const expected = [_][]const u8{};
    const word = "mass";
    const candidates = [_][]const u8{"last"};
    try testAnagrams(&expected, word, &candidates);
}
test "detects anagrams case-insensitively" {
    const expected = [_][]const u8{"Carthorse"};
    const word = "Orchestra";
    const candidates = [_][]const u8{ "cashregister", "Carthorse", "radishes" };
    try testAnagrams(&expected, word, &candidates);
}
test "detects anagrams using case-insensitive subject" {
    const expected = [_][]const u8{"carthorse"};
    const word = "Orchestra";
    const candidates = [_][]const u8{ "cashregister", "carthorse", "radishes" };
    try testAnagrams(&expected, word, &candidates);
}
test "detects anagrams using case-insensitive possible matches" {
    const expected = [_][]const u8{"Carthorse"};
    const word = "orchestra";
    const candidates = [_][]const u8{ "cashregister", "Carthorse", "radishes" };
    try testAnagrams(&expected, word, &candidates);
}
test "does not detect an anagram if the original word is repeated" {
    const expected = [_][]const u8{};
    const word = "go";
    const candidates = [_][]const u8{"goGoGO"};
    try testAnagrams(&expected, word, &candidates);
}
test "anagrams must use all letters exactly once" {
    const expected = [_][]const u8{};
    const word = "tapper";
    const candidates = [_][]const u8{"patter"};
    try testAnagrams(&expected, word, &candidates);
}
test "words are not anagrams of themselves" {
    const expected = [_][]const u8{};
    const word = "BANANA";
    const candidates = [_][]const u8{"BANANA"};
    try testAnagrams(&expected, word, &candidates);
}
test "words are not anagrams of themselves even if letter case is partially different" {
    const expected = [_][]const u8{};
    const word = "BANANA";
    const candidates = [_][]const u8{"Banana"};
    try testAnagrams(&expected, word, &candidates);
}
test "words are not anagrams of themselves even if letter case is completely different" {
    const expected = [_][]const u8{};
    const word = "BANANA";
    const candidates = [_][]const u8{"banana"};
    try testAnagrams(&expected, word, &candidates);
}
test "words other than themselves can be anagrams" {
    const expected = [_][]const u8{"Silent"};
    const word = "LISTEN";
    const candidates = [_][]const u8{ "LISTEN", "Silent" };
    try testAnagrams(&expected, word, &candidates);
}
