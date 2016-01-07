/*------------------------------------------------------
 Company:           Valentys Ltda.
 Author:            David Gaete <dmunozgaete@gmail.com> (https://github.com/dmunozgaete)
 
 Description:       Sport Selector Dialog Controller
------------------------------------------------------*/
(function()
{
    var closureContext = null;
    var closureModal = null;
    var result = null;

    //MODAL DIALOG (SHARE)
    angular.module('app.controllers')
        .controller('SportDialogController', function(
            $scope,
            $state,
            $log,
            $ionicModal,
            $Configuration
        )
        {

            //---------------------------------------------------
            // Model
            $scope.collections = $Configuration.get("collections");
            $scope.data = angular.copy(closureContext,
            {
                sport: null
            });

            //-------------------------------------------
            // Model
            $scope.toggle = function(item)
            {
                $scope.data.sport = item;
            };

            $scope.select = function()
            {

                $scope.data.sport = $scope.data.sport.identifier;

                result = $scope.data;
                closureModal.remove();
            };

            $scope.cancel = function()
            {
                result = null;
                closureModal.remove();
            };

        });

    // SERVICE
    angular.module("app.services")
        .provider('SportDialog', function()
        {
            var $ref = this;

            this.$get = function($log, $q, $ionicModal)
            {
                var self = {};

                //ADD NEW FACTORY
                self.show = function(context)
                {
                    var defer = $q.defer();
                    closureContext = context;

                    //SHOW DIALOG
                    $ionicModal.fromTemplateUrl('views/firstRun/configure/directives/dialogs/sports.html',
                    {
                        animation: 'slide-in-up',
                        backdropClickToClose: false,
                        focusFirstInput: false
                    }).then(function(modalDialog)
                    {
                        closureModal = modalDialog;
                        closureModal.show();

                        // Execute action on hide modal
                        closureModal.scope.$on('modal.removed', function()
                        {
                            //CANCEL
                            if (!result)
                            {
                                defer.reject(result);
                            }
                            else
                            {
                                //SAVE
                                defer.resolve(result);
                            }

                        });


                    });


                    return defer.promise;
                };

                return self;
            };
        });
})();
