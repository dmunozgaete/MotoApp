angular.module('app.components')

.factory('trackViewer', function($q, $rootScope)
{
    var self = this;
    var components = {};
    var callbacks = [];

    //Entry Point to register
    var $$register = function(component, uniqueID)
    {
        components[uniqueID] = component;

        //Call all then function registered
        angular.forEach(callbacks, function(callback)
        {
            callback.apply(component, [component, uniqueID]);
        });

        callbacks = [];
    };

    //Help to dispose the factory
    var $$unregister = function(uniqueID)
    {
        delete components[uniqueID];
        callbacks = [];
    };

    var _getByHandle = function(uniqueID)
    {
        var identifier = uniqueID;

        if (!identifier)
        {
            var count = Object.keys(components).length;
            if (count === 0)
            {
                throw {
                    message: 'no track-viewer has instantied in the view'
                };
            }

            if (count > 1)
            {
                throw {
                    message: 'when you have more than 1 track-viewer in view, you must send the uniqueID'
                };
            }
            else
            {
                identifier = (function()
                {
                    for (var id in components)
                    {
                        return id;
                    }
                })();

            }
        }

        var component = components[identifier];
        if (!component)
        {
            throw {
                message: 'no track-viewer has found with id {0}'.format([identifier])
            };
        }
        return component;
    };

    self.then = function(callback)
    {
        callbacks.push(callback);
    };

    self.getInstance = function()
    {
        return _getByHandle();
    };

    var exec = function(method, args)
    {
        var instance = self.getInstance();
        instance[method].apply(instance, args);
    };

    self.setPath = function()
    {
        exec("setPath", arguments);
    };

    self.addToPath = function()
    {
        exec("addToPath", arguments);
    };

    //Internal Use
    self.$$register = $$register;
    self.$$unregister = $$unregister;

    return self;
});
