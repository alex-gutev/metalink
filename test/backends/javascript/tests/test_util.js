/**
 * test_util.js
 *
 * Tridash JavaScript runtime library Tests.
 *
 * Copyright 2019-2020 Alexander Gutev
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/**
 * Returns a promise which is resolved with the next value of @a node
 * when it is computed.
 *
 * If the node evaluates to a thunk it is resolved by the promise.
 *
 * @param node The Node
 *
 * @return The Promise
 */
function node_value(node) {
    return Promise.resolve(node.next_value).then(Tridash.resolve);
}

exports.node_value = node_value;

/**
 * Resolve a list value.
 *
 * If @a value is a list, the elements of the list are resolved.
 *
 * @param value The thunk
 * @param n If provided, maximum number of elements to resolve.
 *
 * @return An array containing the elements of the resolved
 *   list. If @a value does not resolve to a list, returns the
 *   resolved value directly.
 */
function resolve_list(value, n) {
    var result = [];

    while (Tridash.resolve(value) !== Tridash.Empty) {
        if (n === 0)
            return result;
        else if (n !== undefined)
            n--;

        result.push(Tridash.resolve(Tridash.head(value)));
        value = Tridash.resolve(Tridash.tail(value));
    }

    return result;
}

/**
 * Resolve a list value.
 *
 * If @a value is a list, it is converted to an array. The list
 * elements themselves are not resolved.
 *
 * @param value The thunk
 * @param n If provided, maximum number of elements to resolve.
 *
 * @return An array containing the elements of the resolved
 *   list. If @a value does not resolve to a list, returns the
 *   resolved value directly.
 */
function list_to_array(value, n) {
    var result = [];

    while (Tridash.resolve(value) !== Tridash.Empty) {
        if (n === 0)
            return result;
        else if (n !== undefined)
            n--;

        result.push(Tridash.head(value));
        value = Tridash.resolve(Tridash.tail(value));
    }

    return result;
}

exports.resolve_list = resolve_list;
exports.list_to_array = list_to_array;
