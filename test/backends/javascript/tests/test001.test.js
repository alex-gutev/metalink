/**
 * test001.test.js
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

require('./test001.js');

var a = Tridash.nodes.a;
var out1 = Tridash.nodes.out1;
var out2 = Tridash.nodes.out2;

describe('Integration Test 1', function() {
    describe('Simple One-Way Binding', function() {
        it('Values of `out1` and `out2` are set to value of `a`', async function() {
            a.set_value(1);

            assert.equal(await util.node_value(out1), 1);
            assert.equal(await util.node_value(out2), 1);
        });

        it('Value of `out1` and `out2` are updated when `a` changes', async function() {
            a.set_value(14);

            assert.equal(await util.node_value(out1), 14);
            assert.equal(await util.node_value(out2), 14);
        });
    });
});
