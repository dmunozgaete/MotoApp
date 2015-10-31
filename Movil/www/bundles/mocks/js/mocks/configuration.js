angular.module('mocks.api')

.run(function(mock, $log)
{
    //-------------------------------------------------------------
    mock.whenGET("/Configuration/State", function(method, url, data)
    {
        var result = {
            timestamp: new Date().toISOString(),
            state: "sync"
        };

        return [
            200,
            result,
            {}
        ];
    });
    //-------------------------------------------------------------

});
