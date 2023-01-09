const std = @import("std");

const glbl_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);

pub const Allocator = struct {
    arena: std.heap.ArenaAllocator,

    pub fn init() Allocator {
        return Allocator{
            .arena = glbl_alloc,
        };
    }

    pub fn deinit(self: *Allocator) void {
        _ = self;
    }

    pub fn allocator(self: *Allocator) std.mem.Allocator {
        return self.arena.allocator();
    }
};
