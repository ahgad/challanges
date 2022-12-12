function ag(object, keys) {
    if (!Array.isArray(keys) || keys.length == 0) throw new Error('Invalid Key');
    if (!(typeof object === 'object'))throw new Error('Invalid object');
    if (!keys) {
        return object;
    }
    if (keys.length == 1) {
        return object[keys[0]];
    } 
    var current = object;
    for (var index in keys) {
        var key = keys[index];
        if (key in current)
            current = current[key];
        else
            return null;
    }
    return current;
}
module.exports = ag;