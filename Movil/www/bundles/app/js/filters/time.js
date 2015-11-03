angular.module('app.filters')

.filter('time', function($log)
{
    return function(seconds)
    {

        if (!seconds)
        {
            return "00:00";
        }

        try
        {

            var rest = Math.floor(seconds % 60);
            var minutes = Math.floor(seconds / 60);

            return "{0}:{1}".format([
                _.padLeft(minutes, 2, '0'),
                _.padLeft(rest, 2, '0')
            ]);

        }
        catch (e)
        {
            return seconds;
        }
    };
});
