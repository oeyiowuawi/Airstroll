class BookingsController < ApplicationController

  before_action :set_booking, only: [:update, :destroy, :show, :edit]

  def create
    if booking_params[:passengers_attributes].nil?
      redirect_to :back, notice: "You must have at least one passenger"
    else
      booking = Booking.new(booking_params)
      if booking.save
        mail_sender(booking)
        redirect_to booking_path(booking)
      else
        redirect_to :back, notice: "Booking failed. Try again!!"
      end
    end
  end

  def index
    @bookings = current_user.bookings
  end

  def edit
    # @booking = Booking.find params[:id]
    @flight = @booking.flight
    @number_of_passengers = @booking.no_of_passenger.to_i
  end

  def update
    # @booking = Booking.find params[:id]
    @booking.update(booking_params)
    mail_sender(@booking, true)
    redirect_to user_profile_path, notice: "Booking successfully updated."
  end

  def reservation
  end

  def destroy
    # @booking = Booking.find params[:id]
    if @booking.destroy
      flash[:success] = "Booking cancelled successfully."
    else
      flash[:alert] = "Unable to cancel the booking, please contact the admin."
    end
    redirect_to user_profile_path
  end

  def find_reservation
    @reservation = Booking.find_booking(params[:bcode], current_user.id)
  end

  def show
    # @booking = Booking.find(params[:id])
    @flight = Flight.find(@booking.flight_id)
  end

  def new
    @flight = Flight.find(params[:id])
    @booking = Booking.new
  end

  private

  def booking_params
    params.require(:booking).permit(:user_id, :no_of_passenger, :flight_id,
                                    passengers_attributes: [:id, :name,
                                                            :email, :_destroy])
  end

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def mail_sender(booking, update = false)
    if current_user && update
      PassengerMailer.update_mail(current_user.name, current_user.email,
                                  booking).deliver_now
    elsif current_user
      PassengerMailer.confirmation(current_user.name,
                                   current_user.email, booking).deliver_later
    else
      passengers = booking.passengers
      passengers.each do |passenger|
        PassengerMailer.confirmation(passenger.name,
                                     passenger.email, booking).deliver_later
      end
    end
  end
end
