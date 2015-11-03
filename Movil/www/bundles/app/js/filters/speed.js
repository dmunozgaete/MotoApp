angular.module('app.filters')

.filter('speed', function($log, $filter)
{
    return function(calories)
    {

        if (!calories)
        {
            return "0,00";
        }

        try
        {
            return $filter('currency')(calories, '', 2);
        }
        catch (e)
        {
            return calories;
        }
    };
});
