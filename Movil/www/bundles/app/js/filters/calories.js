angular.module('app.filters')

.filter('calories', function($log, $filter)
{
    return function(calories)
    {

        if (!calories)
        {
            return "0,0";
        }

        try
        {
            return $filter('currency')(calories, '', 1);
        }
        catch (e)
        {
            return calories;
        }
    };
});
