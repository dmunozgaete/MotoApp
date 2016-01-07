/*------------------------------------------------------
 Company:           Valentys Ltda.
 Author:            David Gaete <dmunozgaete@gmail.com> (https://github.com/dmunozgaete)
 
 Description:       Share Dialog Controller , to publish the route
------------------------------------------------------*/
(function()
{
    var closureContext = null;
    var result = null;
    var closureModal = null;

    //MODAL DIALOG (SHARE)
    angular.module('app.controllers')
        .controller('FilterDialogController', function(
            $scope,
            $state,
            $log,
            $ionicModal
        )
        {
            $scope.data = angular.copy(closureContext,
            {});

            //-------------------------------------------
            // Model
            $scope.share = function()
            {
                result = $scope.data;
                closureModal.remove();
            };

            $scope.cancel = function()
            {
                result = null;
                closureModal.remove();
            };

            //FIX UGGLY ERROR ON IONIC RANGE IN a MODAL ONLY IN IOS!!!!
            //http://stackoverflow.com/questions/26845263/ionic-range-cannot-click-on-ios
            $scope.onTap = function(e)
            {
                if (ionic.Platform.isIOS())
                {
                    var distance = Math.round(
                        (e.target.max / e.target.offsetWidth) * (e.gesture.touches[0].screenX - e.target.offsetLeft),
                        0
                    );
                    $scope.data.distance = distance > 0 ? distance : 1;
                }
            };

        });

    // SERVICE
    angular.module("app.services")
        .provider('FilterDialog', function()
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
                    $ionicModal.fromTemplateUrl('views/routes/discover/dialogs/filters.html',
                    {
                        animation: 'slide-in-up',
                        backdropClickToClose: true,
                        focusFirstInput: false
                    }).then(function(modalDialog)
                    {
                        closureModal = modalDialog;
                        closureModal.show();

                        // Execute action on hide modal
                        closureModal.scope.$on('modal.hidden', function()
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
