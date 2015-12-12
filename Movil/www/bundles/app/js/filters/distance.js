angular.module('app.filters')

.filter('distance', function($log, $filter)
{
    return function(distance)
    {

        if (!distance)
        {
            return "0,00";
        }

        try
        {
            return $filter('currency')(distance, '', 1);
        }
        catch (e)
        {
            return distance;
        }
    };
});
