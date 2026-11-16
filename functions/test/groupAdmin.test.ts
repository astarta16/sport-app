import { describe, expect, it } from 'vitest';
import { hasRoom, parseCapacity, validGroupCoaches, withinGroupLimit } from '../src/lib/groupAdmin';

describe('v1.9.1 group administration', () => {
  it('coaches must be approved coaches of the same club', () => {
    const ok = { role: 'coach', coachStatus: 'approved', clubIds: ['c1'] };
    expect(validGroupCoaches('c1', [ok])).toBe(true);
    expect(validGroupCoaches('c1', [])).toBe(false);
    expect(validGroupCoaches('c1', [undefined])).toBe(false);
    expect(validGroupCoaches('c1', [{ ...ok, clubIds: ['c2'] }])).toBe(false);
    expect(validGroupCoaches('c1', [{ ...ok, coachStatus: 'pending' }])).toBe(false);
    expect(validGroupCoaches('c1', [{ ...ok, role: 'parent' }])).toBe(false);
  });
  it('capacity is optional, 1..500', () => {
    expect(parseCapacity(undefined)).toBeNull();
    expect(parseCapacity(20)).toBe(20);
    expect(parseCapacity(0)).toBe('invalid');
    expect(parseCapacity(501)).toBe('invalid');
    expect(parseCapacity(2.5)).toBe('invalid');
  });
  it('a full group has no room; existing members always fit', () => {
    expect(hasRoom(2, ['a', 'b'], 'c')).toBe(false);
    expect(hasRoom(2, ['a', 'b'], 'a')).toBe(true);
    expect(hasRoom(undefined, ['a', 'b'], 'c')).toBe(true);
    expect(hasRoom(3, ['a', 'b'], 'c')).toBe(true);
  });
  it('organization group limit', () => {
    expect(withinGroupLimit(4, 5)).toBe(true);
    expect(withinGroupLimit(5, 5)).toBe(false);
    expect(withinGroupLimit(99, undefined)).toBe(true);
  });
});
