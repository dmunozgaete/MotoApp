angular.route('app.profile/edit/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $Identity,
    $LocalStorage,
    $cordovaContacts,
    $ionicLoading,
    $cordovaDialogs,
    $Configuration,
    Rewards
)
{

    //---------------------------------------------------
    // Model
    $scope.collections = $Configuration.get("collections");
    $scope.data = $Identity.getCurrent().property("personal");

    //------------------------------------------------
    //Get Sport Item in the collection
    $scope.data.sport = _.find($scope.collections.sportTypes,
    {
        identifier: $scope.data.sport
    });


    //------------------------------------------------
    // Action's
    $scope.save = function(data)
    {

        $ionicLoading.show(
        {
            template: 'Actualizando...'
        });

        data.sport = data.sport.identifier;

        $Api.update("/Accounts/Me", data)
            .success(function(response)
            {

                //Extend the identity to add personal data
                $Identity.extend("personal", data);

                //Upate user personal data!
                var label = $Configuration.get("localstorageStamps").personal_data;
                var userData = $LocalStorage.setObject(label, data);

                $ionicLoading.hide();

                Rewards.check('PROFILE');

                //Set Profile
                $scope.back();

            })
            .error(function()
            {
                $ionicLoading.hide();
            });

    };

    $scope.back = function()
    {
        history.back();
    };

    $scope.delete = function(item, index)
    {

        $cordovaDialogs.confirm('¿Desea elminar este contacto?', 'Remover Contacto', ['Cancelar', 'Remover'])
            .then(function(buttonIndex)
            {
                if (buttonIndex == 2)
                {
                    $scope.data.emergencyPhones.splice(index, 1);
                }
            });


        return false;
    };

    $scope.pickContact = function()
    {
        $cordovaContacts.pickContact()
            .then(function(contactPicked)
            {
                if (contactPicked.phoneNumbers && contactPicked.phoneNumbers.length > 0)
                {
                    var phone = contactPicked.phoneNumbers[0].value;

                    $scope.data.emergencyPhones.push(
                        phone
                    );
                }

            });

    };

});
