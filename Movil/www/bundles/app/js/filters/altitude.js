angular.module('app.filters')

.filter('altitude', function($log, $filter)
{
    return function(altitude)
    {

        if (!altitude)
        {
            return "0,00";
        }

        try
        {
            return $filter('currency')(altitude, '', 1);
        }
        catch (e)
        {
            return altitude;
        }
        
    };
});
