/**
 * test032.test.js
 *
 * Tridash WebAssembly Backend Tests
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

const Tridash = require('./tridash.min.js');
const assert = require('assert');

const mod = require('./test032.js');

describe('Integration Test 32', function() {
    var module, x, delta, output;

    before(async () => {
        module = await mod.module;

        x = module.nodes.x;
        delta = module.nodes.delta;
        output = module.nodes.output;
    });

    describe('Outer Node References', function() {
        describe('Set `x` = 1, `delta` = 1', function () {
            it('`output` = 2', function() {
                module.set_values([[x, 1], [delta, 1]]);

                assert.equal(output.get_value(), 2);
            });
        });

        describe('Set `delta` = 2', function () {
            it('`output` = 3', function() {
                delta.set_value(2);

                assert.equal(output.get_value(), 3);
            });
        });

        describe('Set `x` = 5', function () {
            it('`output` = 7', function() {
                x.set_value(5);

                assert.equal(output.get_value(), 7);
            });
        });
    });
});
