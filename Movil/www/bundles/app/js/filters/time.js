angular.module('app.filters')

.filter('time', function($log)
{
    return function(seconds)
    {

        if (!seconds)
        {
            return "00:00:00";
        }

        try
        {

/*
hours = Math.floor(totalSec / 3600);
  440:             minutes = Math.floor((totalSec - (hours * 3600)) / 60);
  441:             seconds = (totalSec - ((minutes * 60) + (hours * 3600))); 
  444:                 hours = "0" + (Math.floor(totalSec / 3600)).toString();
  448:                 minutes = "0" + (Math.floor((totalSec - (hours * 3600)) / 60)).toString();
  452:                 seconds = "0" + (totalSec - ((minutes * 60) + (hours * 3600))).toString(); 
*/

            var rest = Math.floor(seconds % 60);
            var hours = Math.floor(seconds / 3600);
            var minutes = Math.floor((seconds - (hours * 3600)) / 60);

            return "{0}:{1}:{2}".format([
                _.padLeft(hours, 2, '0'),
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
