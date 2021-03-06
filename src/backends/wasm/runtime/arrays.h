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

#ifndef TRIDASH_ARRAYS_H
#define TRIDASH_ARRAYS_H

#include <stdint.h>
#include <stddef.h>

#include "macros.h"

#define TRIDASH_ARRAY_SIZE(n) (offsetof(struct tridash_object, array.elements) + ((n) * sizeof(uintptr_t)))

/**
 * Tridash Array
 */
struct array {
    /** Number of elements */
    size_t size;
    /** Array of elements */
    uintptr_t elements[];
};

/**
 * Copy an array structure. Only the references to the elements of the
 * array are copied, not the elements themselves.
 *
 * The difference between this function and gc_copy_array is that the
 * latter is only intended to be used during garbage collection and
 * thus does not take into account the possibility of a garbage
 * collection being initiated during copying. This function can be
 * used safely even if a garbage collection is initiated during
 * copying.
 *
 * @param src Pointer to the array object.
 * @return Pointer to the copied object.
 */
void *copy_array(const void *src);

/**
 * Copy an array structure. Only the references to the elements of the
 * array are copied, not the elements themselves.
 *
 * @param src Pointer to the array object.
 * @return Pointer to the copied object.
 */
void *gc_copy_array(const void *src);

/**
 * Copy the elements stored in an array and update the references.
 *
 * @param src Pointer to the array object.
 * @return Pointer to the first byte following the array object.
 */
void *gc_copy_array_elements(void *src);

#endif /* TRIDASH_ARRAYS_H */
