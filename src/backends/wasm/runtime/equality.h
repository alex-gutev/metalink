/**
 * Tridash Wasm32 Runtime Library
 * Copyright (C) 2020  Alexander Gutev
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Linking this library statically or dynamically with other modules is
 * making a combined work based on this library. Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * As a special exception, the copyright holders of this library give
 * you permission to link this library with independent modules to
 * produce an executable, regardless of the license terms of these
 * independent modules, and to copy and distribute the resulting
 * executable under terms of your choice, provided that you also meet,
 * for each linked independent module, the terms and conditions of the
 * license of that module. An independent module is a module which is
 * not derived from or based on this library. If you modify this
 * library, you may extend this exception to your version of the
 * library, but you are not obliged to do so. If you do not wish to do
 * so, delete this exception statement from your version.
 */

#ifndef TRIDASH_EQUALITY_H
#define TRIDASH_EQUALITY_H

#include <stdint.h>

#include "macros.h"

/**
 * Checks whether two objects are equal.
 *
 * @param a Tridash Object
 * @param b Tridash Object
 *
 * @return Tridash Boolean indicating whether @a a is equal to
 *   @a b.
 */
export uintptr_t object_eq(uintptr_t a, uintptr_t b);

/**
 * Checks whether two objects are not equal.
 *
 * @param a Tridash Object
 * @param b Tridash Object
 *
 * @return Tridash Boolean indicating whether @a a is not equal
 *   to @a b.
 */
export uintptr_t object_neq(uintptr_t a, uintptr_t b);

/**
 * Checks whether two symbol objects are equal.
 *
 * If at least one of the objects is not a symbol, false is returned.
 *
 * NOTE: It is assumed that all symbol objects are created at
 * compile-time, in the constant data section of memory, with a unique
 * symbol object per symbol name.
 *
 * @param a Tridash Symbol Object
 * @param b Tridash Symbol Object
 *
 * @return Tridash Boolean indicating whether @a a and @a b represent
 *   the same Tridash symbol.
 */
export uintptr_t symbol_eq(uintptr_t a, uintptr_t b);

#endif /* TRIDASH_EQUALITY_H */
