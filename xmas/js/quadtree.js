// Quad tree
var Node = (function() {
    function _Node (x, y, width, height, level) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.level = (level != null) ? level : 0;
        this.objs = [];
        this.max_objs = 10;
        this.max_levels = 6;
        this.sub_nodes = [];
    }

    _Node.prototype.add = function(obj) {
        var index;
        if (this.sub_nodes.length !== 0) {
            index = this.getIndex(obj);
            if (index !== -1) {
                this.sub_nodes[index].add(obj);
                return;
            }
        }
        this.objs.push(obj);
        if (this.objs.length > this.max_objs && this.level < this.max_levels) {
            if (this.sub_nodes.length === 0) { this.split(); }
            var _ref = this.objs;
            for (var _i = 0, _len = _ref.length; _i < _len; _i++) {
                var o = _ref[_i];
                index = this.getIndex(o);
                if (index !== -1) {
                    this.sub_nodes[index].add(o);
                    this.remove(o);
                }
            }
        }
    };

    _Node.prototype.getIndex = function (obj) {
        var index = -1;
        var midpoint = {
            x: this.x + this.width * 0.5,
            y: this.y + this.height * 0.5
        };
        var pos = obj.position;

        if (pos.x < midpoint.x && pos.y < midpoint.y) { index = 0; }
        if (pos.x > midpoint.x && pos.y < midpoint.y) { index = 1; }
        if (pos.x > midpoint.x && pos.y > midpoint.y) { index = 2; }
        if (pos.x < midpoint.x && pos.y > midpoint.y) { index = 3; }
        return index;
    };

    _Node.prototype.getNearbyObjs = function (obj) {

        var objs = this.objs.slice(0);
        var index = this.getIndex(obj);
        if (index !== -1 && this.sub_nodes.length !== 0) {
            return this.sub_nodes[index].getNearbyObjs(obj);
        }
        return objs;
    };

    _Node.prototype.remove = function (obj) {
        var index = this.objs.indexOf(obj);
        if (index !== -1) {
            this.objs = this.objs.slice(0, index);
        }
    };

    _Node.prototype.split = function () {
        var half_width = this.width * 0.5;
        var half_height = this.height * 0.5;
        var level = this.level + 1;
        var x = this.x;
        var y = this.y;
        this.sub_nodes[0] = new _Node(x, y, half_width, half_height, level);
        this.sub_nodes[1] = new _Node(x + half_width, y, half_width, half_height, level);
        this.sub_nodes[2] = new _Node(x + half_width, y + half_height, half_width, half_height, level);
        this.sub_nodes[3] = new _Node(x, y + half_height, half_width, half_height, level);
    };

    _Node.prototype.clear = function () {
        this.objs = [];
        if (this.sub_nodes.length !== 0) {
            var _ref = this.sub_nodes;
            for (var _i = 0, _len = _ref.length; _i < _len; _i++) {
                var node = _ref[_i];
                node.clear();
            }
        }
        this.sub_nodes = [];
    };

    return _Node;

})();