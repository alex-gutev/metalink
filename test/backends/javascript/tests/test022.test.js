/**
 * test022.test.js
 *
 * Tridash JavaScript runtime library Tests.
 *
 * Copyright 2020 Alexander Gutev
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

const Tridash = require('../runtime/tridash.js');
const assert = require('assert');

const mod = require('./test022.js');

const n = mod.nodes.n;
const output = mod.nodes.output;

describe('Integration Test 22', function() {
    describe('Recursive Meta-Nodes', function() {
        describe('Set `n` = 1', function() {
            it('`output` = factorial(1) = 1', function() {
                n.set_value(1);
                assert.equal(output.get_value(), 1);
            });
        });

        describe('Set `n` = 2', function() {
            it('`output` = factorial(2) = 2', function() {
                n.set_value(2);
                assert.equal(output.get_value(), 2);
            });
        });

        describe('Set `n` = 5', function() {
            it('`output` = factorial(5) = 120', function() {
                n.set_value(5);
                assert.equal(output.get_value(), 120);
            });
        });
    });
});
