/**
 * test017.test.js
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
var Tridash = require('../runtime/tridash.js');
var assert = require('assert');
var util = require('./test_util.js');

require('./test017.js');

var counter = Tridash.nodes['counter'];
var start = Tridash.nodes['start'];
var clicked = Tridash.nodes['clicked?'];
var delta = Tridash.nodes['delta'];

describe('Integration Test 17', function() {
    describe('Explicit States Counter With Delta', function() {
        describe('Setting Initial Counter Value', function() {
            it('Initial value of counter is 0', async function() {
                start.set_value(0);
                assert.equal(await util.node_value(counter), 0);
            });
        });

        describe('Incrementing Counter Value', function() {
            it('`counter` incremented after changing to increment state', async function() {
                delta.set_value(1);
                clicked.set_value(1);

                assert.equal(await util.node_value(counter), 1);
            });

            it('`counter` value retained after changing back to default state', async function() {
                clicked.set_value(false);
                assert.equal(await util.node_value(counter), 1);
            });

            it('`counter` incremented again after changing back to increment state', async function() {
                clicked.set_value(true);
                assert.equal(await util.node_value(counter), 2);
            });
        });

        describe('Changing Delta', function() {
            it('Changing `delta` does not change `counter` value', async function() {
                delta.set_value(10);
                clicked.set_value(false);

                assert.equal(await util.node_value(counter), 2);
            });

            it('`counter` incremented with new delta when changing to increment state', async function() {
                clicked.set_value(true);
                assert.equal(await util.node_value(counter), 12);
            });
        });

        describe('Resetting Counter Value', function() {
            it('`counter` value reset when changing `start`', async function() {
                start.set_value(5);
                assert.equal(await util.node_value(counter), 5);
            });
        });
    });
});
