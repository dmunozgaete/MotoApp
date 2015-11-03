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
            return $filter('currency')(distance, '', 2);
        }
        catch (e)
        {
            return distance;
        }
    };
});
