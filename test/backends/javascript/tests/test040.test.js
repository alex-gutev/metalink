/**
 * test040.test.js
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

require('./test040.js');
var in_x = Tridash.nodes.in_x;
var in_y = Tridash.nodes.in_y;
var in_z = Tridash.nodes.in_z;

var output = Tridash.nodes.output;

describe('Integration Test 40', function() {
    describe('Handling Failures with Explicit Contexts', function() {
        describe('Set `in_x` = "1", `in_y` = "2", `in_z` = "3"', function() {
            Tridash.set_values([[in_x, "1"], [in_y, "2"], [in_z, "3"]]);
            var value = util.node_value(output);

            it('`output` = 1', async function() {
                assert.equal(await value, 1);
            });
        });

        describe('Set `in_x` = "foo"', function() {
            in_x.set_value("foo");
            var value = util.node_value(output);

            it('`output` = `in_y` = 2', async function() {
                assert.equal(await value, 2);
            });
        });

        describe('Set `in_y` = "-1"', function() {
            in_y.set_value("-1");
            var value = util.node_value(output);

            it('`output` = `in_z` = 3', async function() {
                assert.equal(await value, 3);
            });
        });

        describe('Set `in_y` = "10"', function() {
            in_y.set_value("10");
            var value = util.node_value(output);

            it('`output` = `in_y` = 10', async function() {
                assert.equal(await value, 10);
            });
        });

        describe('Set `in_x` = "-5"', function() {
            in_x.set_value("-5");
            var value = util.node_value(output);

            it('`output` = `in_z` = 3', async function() {
                assert.equal(await value, 3);
            });
        });
    });
});