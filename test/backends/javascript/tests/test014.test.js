/**
 * test014.test.js
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

var Tridash = require('../runtime/tridash.js');
var assert = require('assert');
var util = require('./test_util.js');

require('./test014.js');

var a = Tridash.nodes.a;
var b = Tridash.nodes.b;
var output = Tridash.nodes.output;

describe('Integration Test 14', function() {
    describe('Conditional Bindings Based on Failure Type', function() {
        it('`output` is set to `a` when `a + 1 > 3`', async function() {
            a.set_value(3);
            assert.equal(await util.node_value(output), 3);
        });

        it('`output` is set to `b` when `a + 1 < 3`', async function() {
            Tridash.set_values([[a, 1], [b, 10]]);
            assert.equal(await util.node_value(output), 10);
        });

        it('`output` is set to `a` is not a number', async function() {
            a.set_value("x");
            assert.equal(await util.node_value(output), "other");
        });

    });
});